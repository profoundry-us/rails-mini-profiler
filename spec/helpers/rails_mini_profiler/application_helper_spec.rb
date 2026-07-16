# frozen_string_literal: true

require 'rails_helper'

module RailsMiniProfiler
  RSpec.describe ApplicationHelper do
    describe 'break_opportunities' do
      it 'adds <wbr> after namespace separators in class names' do
        expect(helper.break_opportunities('Daisy::Layout::DrawerComponent'))
          .to eq('Daisy::<wbr>Layout::<wbr>DrawerComponent')
      end

      it 'adds <wbr> after slashes and underscores in paths' do
        expect(helper.break_opportunities('app/controllers/application_controller.rb'))
          .to eq('app/<wbr>controllers/<wbr>application_<wbr>controller.rb')
      end

      it 'escapes HTML before inserting break opportunities' do
        expect(helper.break_opportunities('<script>_x'))
          .to eq('&lt;script&gt;_<wbr>x')
      end

      it 'returns an html-safe string' do
        expect(helper.break_opportunities('A::B')).to be_html_safe
      end

      it 'returns nil for nil input' do
        expect(helper.break_opportunities(nil)).to be_nil
      end
    end
  end
end
