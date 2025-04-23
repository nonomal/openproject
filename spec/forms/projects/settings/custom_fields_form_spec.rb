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
#
require "spec_helper"

RSpec.describe Projects::Settings::CustomFieldsForm, type: :forms do
  let(:string_project_custom_field) { create(:string_project_custom_field, name: "String field", is_required: true) }
  let(:boolean_project_custom_field) { create(:boolean_project_custom_field, name: "Boolean field", is_required: true) }
  let(:text_project_custom_field) { create(:text_project_custom_field, name: "Text field", is_required: true) }
  let(:integer_project_custom_field) { create(:integer_project_custom_field, name: "Integer field", is_required: true) }
  let(:float_project_custom_field) { create(:float_project_custom_field, name: "Float field", is_required: true) }
  let(:date_project_custom_field) { create(:date_project_custom_field, name: "Date field", is_required: true) }
  let(:list_project_custom_field) { create(:list_project_custom_field, name: "List field", is_required: true) }
  let(:version_project_custom_field) { create(:version_project_custom_field, name: "Version field", is_required: true) }
  let(:user_project_custom_field) { create(:user_project_custom_field, name: "User field", is_required: true) }
  let(:link_project_custom_field) { create(:link_project_custom_field, name: "Link field", is_required: true) }

  let(:custom_field_values) do
    {
      "#{string_project_custom_field.id}": "str_val",
      "#{boolean_project_custom_field.id}": true,
      "#{integer_project_custom_field.id}": 43,
      "#{float_project_custom_field.id}": 78.23
    }
  end

  let(:model) { create(:project, custom_field_values:) }

  let(:current_user) { build_stubbed(:admin) }

  current_user { build_stubbed(:admin) }

  include_context "with rendered form"

  it "renders fields" do
    expect(page).to have_field "String field", with: "str_val", required: true
    expect(page).to have_checked_field "Boolean field", required: true
    expect(page).to have_field "Integer field", with: "43", required: true
    expect(page).to have_field "Float field", with: "78.23", required: true
  end
end
