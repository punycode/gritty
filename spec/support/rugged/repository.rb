require 'rugged'

require 'archive/tar/minitar'
require 'rspec'
require 'rspec/matchers/built_in/yield'
require 'fileutils'
require 'zlib'

shared_context 'with repository' do |scoped_as|

    TEST_REPOSITORY_TAR = File.join(File.dirname(__FILE__), 'test.git.tar.gz')
    TEST_REPOSITORY = File.join(File.dirname(__FILE__), '../../..', 'tmp', 'test.git')

    subject(:repository) { Rugged::Repository.new(TEST_REPOSITORY) }

    def create_test_repo
        FileUtils.rm_rf(TEST_REPOSITORY)
        FileUtils.mkdir_p(TEST_REPOSITORY)
        tgz = Zlib::GzipReader.new(File.open(TEST_REPOSITORY_TAR, 'rb'))
        Archive::Tar::Minitar.unpack(tgz, TEST_REPOSITORY)
    end

    def cleanup_test_repo; FileUtils.rm_rf(TEST_REPOSITORY); end

    if scoped_as == :each
        around(:each) do |example|
            create_test_repo
            example.run
            cleanup_test_repo
        end
    else
        before(scoped_as) { create_test_repo }
        after(scoped_as) { cleanup_test_repo }
    end
end

RSpec::Matchers.define :contain_commit do |expected|

    match do |actual|
        if actual.is_a?(Proc)
            actual = RSpec::Matchers::BuiltIn::YieldProbe.probe(actual).successive_yield_args
        end
        actual.any? do |commit|
            commit = commit.oid if commit.is_a?(Rugged::Commit)
            case expected
            when Rugged::Commit
                commit.should eq(expected.oid)
            when Regexp
                commit =~ expected
            when String
                commit.should eq(expected)
            else
                false
            end
        end
    end
end

