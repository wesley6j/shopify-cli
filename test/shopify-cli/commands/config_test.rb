require "test_helper"

module ShopifyCli
  module Commands
    class ConfigTest < MiniTest::Test
      include TestHelpers::FakeFS

      TEST_FEATURE = :feature_flag_test

      def setup
        super
        ShopifyCli::Core::Monorail.stubs(:log).yields
      end

      def test_help_argument_calls_help
        @context.expects(:puts).with(ShopifyCli::Commands::Config.help)
        run_cmd("config help")
      end

      def test_feature_help_argument_calls_help
        @context.expects(:puts).with(ShopifyCli::Commands::Config::Feature.help)
        run_cmd("config feature --help")
      end

      def test_analytics_help_argument_calls_help
        @context.expects(:puts).with(ShopifyCli::Commands::Config::Analytics.help)
        run_cmd("config analytics --help")
      end

      def test_no_arguments_calls_help
        @context.expects(:puts).with(ShopifyCli::Commands::Config.help)
        run_cmd("config")
      end

      def test_no_feature_calls_help
        @context.expects(:puts).with(ShopifyCli::Commands::Config.help)
        run_cmd("config feature")
      end

      def test_will_enable_a_feature_that_is_disabled
        ShopifyCli::Feature.disable(TEST_FEATURE)
        @context.expects(:puts).with(@context.message("core.config.feature.enabled", TEST_FEATURE))
        run_cmd("config feature #{TEST_FEATURE} --enable")
        assert ShopifyCli::Feature.enabled?(TEST_FEATURE)
      end

      def test_will_disable_a_feature_that_is_enabled
        ShopifyCli::Feature.enable(TEST_FEATURE)
        @context.expects(:puts).with(@context.message("core.config.feature.disabled", TEST_FEATURE))
        run_cmd("config feature #{TEST_FEATURE} --disable")
        refute ShopifyCli::Feature.enabled?(TEST_FEATURE)
      end

      def test_will_enable_analytics_that_is_disabled
        # Given
        ShopifyCli::DB.expects(:get)
          .with(ShopifyCli::Constants::StoreKeys::ANALYTICS_ENABLED)
          .returns(false)
        ShopifyCli::DB.expects(:set)
          .with(ShopifyCli::Constants::StoreKeys::ANALYTICS_ENABLED => true)

        # When/then
        run_cmd("config analytics --enable")
      end

      def test_will_disable_analytics_that_is_enabled
        # Given
        ShopifyCli::DB.expects(:get)
          .with(ShopifyCli::Constants::StoreKeys::ANALYTICS_ENABLED)
          .returns(true)
        ShopifyCli::DB.expects(:set)
          .with(ShopifyCli::Constants::StoreKeys::ANALYTICS_ENABLED => false)

        # When/then
        run_cmd("config analytics --disable")
      end
    end
  end
end
