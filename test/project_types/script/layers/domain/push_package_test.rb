# frozen_string_literal: true

require "project_types/script/test_helper"

describe Script::Layers::Domain::PushPackage do
  let(:uuid) { "uuid" }
  let(:extension_point_type) { "discount" }
  let(:script_id) { "id" }
  let(:script_json) { { "version" => "1", "title" => "title" } }
  let(:api_key) { "fake_key" }
  let(:force) { false }
  let(:script_content) { "(module)" }
  let(:compiled_type) { "wasm" }
  let(:metadata) { Script::Layers::Domain::Metadata.new("1", "0", true) }
  let(:library_language) { "assemblyscript" }
  let(:library_version) { "1.0.0" }
  let(:push_package) do
    Script::Layers::Domain::PushPackage.new(
      id: id,
      uuid: uuid,
      extension_point_type: extension_point_type,
      script_json: script_json,
      script_content: script_content,
      compiled_type: compiled_type,
      metadata: metadata,
      library_language: library_language,
      library_version: library_version,
    )
  end
  let(:script_service) { Minitest::Mock.new }
  let(:id) { "push_package_id" }

  describe ".new" do
    subject { push_package }

    it "should construct new PushPackage" do
      assert_equal id, subject.id
      assert_equal script_content, subject.script_content
      assert_equal uuid, subject.uuid
    end
  end
end
