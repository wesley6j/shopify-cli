# frozen_string_literal: true
require_relative "file"

require "pathname"
require "time"

module ShopifyCLI
  module Theme
    class InvalidThemeRole < StandardError; end

    class Theme
      attr_reader :root, :id

      def initialize(ctx, root: nil, id: nil, name: nil, role: nil)
        @ctx = ctx
        @root = Pathname.new(root) if root
        @id = id
        @name = name
        @role = role
      end

      def theme_files
        glob(["**/*.liquid", "**/*.json", "assets/*"]).uniq
      end

      def static_asset_files
        glob("assets/*").reject(&:liquid?)
      end

      def liquid_files
        glob("**/*.liquid")
      end

      def json_files
        glob("**/*.json")
      end

      def glob(pattern)
        root.glob(pattern).map { |path| File.new(path, root) }
      end

      def theme_file?(file)
        theme_files.include?(self[file])
      end

      def static_asset_paths
        static_asset_files.map(&:relative_path)
      end

      def [](file)
        case file
        when File
          file
        when Pathname
          File.new(file, root)
        when String
          File.new(root.join(file), root)
        end
      end

      def shop
        AdminAPI.get_shop_or_abort(@ctx)
      end

      def editor_url
        "https://#{shop}/admin/themes/#{id}/editor"
      end

      def name
        return @name if @name
        load_info_from_api.name
      end

      def role
        if @role == "main"
          # Main theme is called Live in UI
          "live"
        elsif @role
          @role
        else
          load_info_from_api.role
        end
      end

      def live?
        role == "live"
      end

      def development?
        role == "development"
      end

      def preview_url
        if live?
          "https://#{shop}/"
        else
          "https://#{shop}/?preview_theme_id=#{id}"
        end
      end

      def create
        raise InvalidThemeRole, "Can't create live theme. Use publish." if live?

        _status, body = ShopifyCLI::AdminAPI.rest_request(
          @ctx,
          shop: shop,
          path: "themes.json",
          body: JSON.generate({
            theme: {
              name: name,
              role: role,
            },
          }),
          method: "POST",
          api_version: "unstable",
        )

        @id = body["theme"]["id"]
      end

      def delete
        AdminAPI.rest_request(
          @ctx,
          shop: shop,
          method: "DELETE",
          path: "themes/#{id}.json",
          api_version: "unstable",
        )
      end

      def publish
        return if live?
        AdminAPI.rest_request(
          @ctx,
          shop: shop,
          method: "PUT",
          path: "themes/#{id}.json",
          api_version: "unstable",
          body: JSON.generate(theme: {
            role: "main",
          })
        )
        @role = "live"
      end

      def current_development?
        development? && id == ShopifyCLI::DB.get(:development_theme_id)
      end

      def foreign_development?
        development? && id != ShopifyCLI::DB.get(:development_theme_id)
      end

      def to_h
        {
          id: id,
          name: name,
          role: role,
          shop: shop,
          editor_url: editor_url,
          preview_url: preview_url,
        }
      end

      def self.all(ctx, root: nil)
        _status, body = AdminAPI.rest_request(
          ctx,
          shop: AdminAPI.get_shop_or_abort(ctx),
          path: "themes.json",
          api_version: "unstable",
        )

        body["themes"]
          .sort_by { |attributes| Time.parse(attributes["updated_at"]) }
          .reverse
          .map do |attributes|
            new(
              ctx,
              root: root,
              id: attributes["id"],
              name: attributes["name"],
              role: attributes["role"],
            )
          end
      end

      private

      def load_info_from_api
        _status, body = AdminAPI.rest_request(
          @ctx,
          shop: shop,
          path: "themes/#{id}.json",
          api_version: "unstable",
        )

        @name = body.dig("theme", "name")
        @role = body.dig("theme", "role")

        self
      end
    end
  end
end
