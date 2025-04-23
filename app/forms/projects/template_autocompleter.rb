# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects
  class TemplateAutocompleter < ApplicationForm
    form do |f|
      f.project_autocompleter(
        name: "template_id",
        label: I18n.t("js.project.use_template"),
        autocomplete_options: {
          focusDirectly: false,
          dropdownPosition: "bottom",
          inputValue: input_value,
          placeholder: I18n.t("js.project.no_template_selected"),
          filters: [
            { name: "user_action", operator: "=", values: ["projects/copy"] },
            { name: "templated", operator: "=", values: ["t"] }
          ],
          data: {
            action: "change->highlight-when-value-selected#itemSelected change->auto-submit#submit",
            "qa-field-name": "use_template"
          }
        }
      )
    end

    def initialize(template:)
      super()
      @template = template
    end

    private

    def input_value
      @template&.id
    end
  end
end
