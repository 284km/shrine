require "test_helper"

describe "retry plugin" do
  it "retries upload" do
    storage = Class.new(Shrine::Storage::Memory) do
      def upload(io, location, metadata = {})
        if @raised
          super
        else
          @raised = true
          raise "timeout error"
        end
      end
    end

    @shrine = Class.new(Shrine) { plugin :retry, tries: 3 }
    @shrine.storages[:store] = storage.new
    @shrine.new(:store).upload(fakeio)
  end

  it "retries specified number of times" do
    storage = Class.new(Shrine::Storage::Memory) do
      def upload(io, location, metadata = {})
        @counter ||= 1

        if @counter == 3
          super
        else
          @counter += 1
          raise "timeout error"
        end
      end
    end

    @shrine = Class.new(Shrine) { plugin :retry, tries: 3 }
    @shrine.storages[:store] = storage.new
    @shrine.new(:store).upload(fakeio)

    @shrine = Class.new(Shrine) { plugin :retry, tries: 2 }
    @shrine.storages[:store] = storage.new
    assert_raises(RuntimeError) { @shrine.new(:store).upload(fakeio) }
  end
end