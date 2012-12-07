require 'rugged'

module Rugged
    class Commit
        def merge?
            parent_oids.size > 1
        end

        def modify(repository, new_args)
            args = self.to_hash.merge(new_args)
            Commit.create(repository, args)
        end
    end

    class Repository
        REVPARSE_REGEX = /^(?<hide>\^)?(?<left>(?:(?!\.\.\.?).)+)(?:\.\.(?<sym>\.)?(?<right>.+))?$/
        BACKUP_REGEX = /^refs\/((?:heads|tags)\/.*)$/
        OID_REGEX = /[0-9a-fA-F]{5,40}/

        def rev_parse_git(*refspecs)
            refspecs.flatten.reduce([]) do |collect,spec|
                if match = REVPARSE_REGEX.match(spec)
                    hide, left, sym, right = match.captures
                    left = rev_parse_oid(left)
                    if right.nil?
                        collect << (hide ? "^#{left}" : left)
                    elsif sym
                        raise "Symmetric difference not implemented yet."
                    elsif not hide
                        collect << "^#{left}"
                        collect << rev_parse_oid(right)
                    end
                end
            end
        end

        def walker_with(*refspecs)
            options = refspecs.last.is_a?(Hash) ? refspecs.pop : {}
            refs = rev_parse_git(refspecs) || ["HEAD"]
            walker = Rugged::Walker.new self
            walker.sorting(options[:sorting] || (Rugged::SORT_TOPO | Rugged::SORT_REVERSE))
            refs.each do |ref|
                if ref.start_with? "^"
                    walker.hide(ref[1..-1])
                else
                    walker.push(ref)
                end
            end
            walker
        end

        def walk_with(*refspecs, &block)
            walker = walker_with(*refspecs)
            if block_given?
                walker.each &block
            else
                walker.each
            end
        end

        def filter!(*refspecs)
            options = refspecs.last.is_a?(Hash) ? refspecs.last : {}

            oldrefs = refs(BACKUP_REGEX).map do |ref|
                [ref.resolve, ref.name.gsub(BACKUP_REGEX, 'refs/rugged/\1')]
            end

            parents = Hash.new

            walk_with(*refspecs) do |commit|
                new_commit = yield commit
                new_commit = lookup(new_commit) if new_commit.is_a?(String) and OID_REGEX.match(new_commit)
                unless new_commit == commit
                    candidates = oldrefs.find_all { |ref, dest| ref.target == commit.oid }
                    candidates.each do |ref,dest|
                        Reference.create(self, dest, ref.target, options[:overwrite]||false)
                    end unless options[:nobackup]

                    new_parents = new_commit.parent_oids.map do |parent|
                        parents.key?(parent) ? parents[parent] : parent
                    end

                    unless new_parents == new_commit.parent_oids
                        new_commit = lookup(new_commit.modify(self, :parents => new_parents))
                    end

                    parents[commit.oid] = new_commit.oid

                    candidates.each { |ref,_| ref.target = new_commit.oid }
                end
            end
        end

        def build(tree=nil)
            builder = tree ? Rugged::Tree::Builder.new(tree) : Rugged::Tree::Builder.new
            yield builder if block_given?
            builder.write(self)
        end
    end

    class Tree
        def modify(repository, &block)
            oid = repository.build self, &block
            self.oid == oid ? self : Tree.lookup(repository, oid)
        end

        def subtree(repository, path, replace_blobs=false, &block)
            path = File::Separator+path unless path.start_with? File::Separator
            path = File.expand_path(path)

            if path == File::Separator # just edit the root
                modify repository, &block
            else
                parts = path.split(File::Separator)[1..-1]

                trees = parts.reduce([self]) do |collect,subdir|
                    subhash = collect.last[subdir]
                    collect << Tree.lookup(repository, subhash ? subhash[:oid] : repository.build)
                end

                final = trees.pop.modify(repository, &block)

                trees.zip(parts).reverse.reduce(final) do |subtree,(parent,part)|
                    parent.modify(repository) do |builder|
                        builder << {:name=>part, :oid=>subtree.oid, :filemode=>16384, :type=>:tree}
                    end
                end
            end
        end
    end
end
