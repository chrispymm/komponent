# frozen_string_literal: true

require 'komponent/component'

module KomponentHelper
  def component(component_name, locals = {}, options = {}, &block)
    captured_block = proc { |args| capture(args, &block) } if block_given?
    Komponent::ComponentRenderer.new(
      controller,
      view_flow || (view && view.view_flow),
    ).render(
      component_name,
      locals,
      options,
      &captured_block
    )
  end
  alias :c :component

  def components
    Komponent::Component.all
  end

  def component_properties_doc(component)
    parts = component.split("/")
      component_name = parts.join("_")

      component_module_path = resolved_component_path(component).join("#{component_name}_component")
      require_dependency(component_module_path)
      component_module = "#{component_name}_component".camelize.constantize
      if component_module.respond_to?(:properties)
        content_tag :pre, class: "komponent-code" do
          content_tag :code do
            "#{pretty_locals(component_module.properties)}"
          end
        end
      end
  end

  def component_with_doc(component_name, locals = {}, options = {}, &block)
    captured_output = rendered_component(component_name, locals, options, &block)
    captured_doc = component_doc(component_name, locals)

    captured_output + captured_doc
  end
  alias :cdoc :component_with_doc


  def component_with_doc_tabs(id, component_name, locals = {}, options = {}, html_options = {}, &block)
    captured_output = rendered_component(component_name, locals, options, &block)
    captured_doc = component_doc(component_name, locals)
    captured_html = component_html(captured_output)

    component_tabs = {
      'ruby' => captured_doc,
      'html' => captured_html,
    }

    captured_tabs = capture do
      content_tag :div, class: "komponent-tabs" do
        safe_join([
          component_tabs_nav(id, component_tabs),
          component_tabs_content(id, component_tabs),
        ])
      end
    end
    captured_output + captured_tabs
  end
  alias :cdoc_tabs :component_with_doc_tabs


  private

  def rendered_component(component_name, locals, options, &block)
    component(component_name, locals, options, &block)
  end

  def component_doc(component_name, locals)
    capture do
      content_tag :pre, class: "komponent-code" do
        content_tag :code, class: "ruby" do
          "= component \"#{component_name}\"" + (locals.present? ? ", #{pretty_locals(locals)}" : "")
        end
      end
    end
  end

  def component_html(captured_output)
    capture do
      content_tag :pre, class: "komponent-code" do
        content_tag :code, class: "html" do
          "#{captured_output}"
        end
      end
    end
  end

  def component_tabs_nav(id, tabs)
    content_tag :ul, class: "komponent-tabs__nav" do
      tabs.each_with_index do |(tab_name, content), index|
        concat( content_tag :li, content_tag(:a, "#{tab_name}", href: "#tab-#{id}-#{index}"), class: (index==0 ? 'active' : '') )
      end
    end
  end

  def component_tabs_content(id, tabs)
    content_tag :div, class: "komponent-tabs__content" do
      tabs.each_with_index do |(tab_name, content), index|
        active_class = 'active' if index==0
        concat( content_tag( :div, "#{content}".html_safe, id: "tab-#{id}-#{index}", class: "komponent-tabs__pane #{active_class}") )
      end
    end
  end


  def pretty_locals(locals)
    return nil if locals.blank?
    JSON.pretty_generate(locals).gsub(/^(\s+)"(\w+)":/, "\\1\\2:")
  end

  def resolved_component_path(component)
      Komponent::ComponentPathResolver.new.resolve(component)
  end
end
