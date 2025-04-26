# frozen_string_literal: true

module OpenProject::Projects
  # @logical_path OpenProject/Projects
  class StatusButtonComponentPreview < ViewComponent::Preview
    # !! Currently nothing happens when changing the status!!
    # @display min_height 400px
    # @param readonly [Boolean]
    # @param size [Symbol] select [small, medium, large]
    def playground(readonly: false, size: :medium)
      user = FactoryBot.build_stubbed(:admin)
      project = FactoryBot.build_stubbed(:project, :with_status)
      render(Projects::StatusButtonComponent.new(project:, user:, readonly:, button_arguments: { size: }))
    end
  end
end
