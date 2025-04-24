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

require "spec_helper"
require_module_spec_helper

module Storages
  module Peripherals
    module ConnectionValidators
      module Nextcloud
        RSpec.describe AmpfConfigurationValidator, :webmock do
          let(:storage) { create(:nextcloud_storage_configured, :as_automatically_managed) }
          let(:project_folder_id) { "1337" }
          let!(:project_storage) do
            create(:project_storage, :as_automatically_managed, project_folder_id:, storage:, project: create(:project))
          end

          let(:files_response) do
            ServiceResult.success(result: StorageFiles.new(
              [StorageFile.new(id: project_folder_id, name: project_storage.managed_project_folder_name)],
              StorageFile.new(id: "root", name: "root"),
              []
            ))
          end

          subject(:validator) { described_class.new(storage) }

          before do
            Registry.stub("nextcloud.queries.files", ->(*) { files_response })
          end

          it "pass all checks" do
            expect(validator.call).to be_success
          end

          context "if userless authentication fails" do
            let(:files_response) { build_failure(code: :unauthorized, payload: nil) }

            it "fails and skips the next checks" do
              results = validator.call

              states = results.tally
              expect(states).to eq({ success: 1, failure: 1, skipped: 2 })
              expect(results[:userless_access]).to be_failure
              expect(results[:userless_access].message).to eq(i18n_message(:userless_access_denied))
            end
          end

          context "if the files request returns not_found" do
            let(:files_response) { build_failure(code: :not_found, payload: nil) }

            it "fails the check" do
              results = validator.call

              expect(results[:group_folder_presence]).to be_failure
              expect(results[:group_folder_presence].message).to eq(i18n_message(:group_folder_not_found))
            end
          end

          context "if the files request returns an unknown error" do
            let(:files_response) { StorageInteraction::Nextcloud::Util.error(:error) }

            before { allow(Rails.logger).to receive(:error) }

            it "fails the check and logs the error" do
              results = validator.call

              expect(results[:files_request]).to be_failure
              expect(results[:files_request].message)
                .to eq(i18n_message(:unknown_error))

              expect(Rails.logger).to have_received(:error).with(/Connection validation failed with unknown error/)
            end
          end

          context "if the files request returns unexpected files" do
            let(:files_response) do
              ServiceResult.success(result: StorageFiles.new(
                [
                  StorageFile.new(id: project_folder_id, name: "I am your father"),
                  StorageFile.new(id: "noooooooooo", name: "testimony_of_luke_skywalker.md")
                ],
                StorageFile.new(id: "root", name: "root"),
                []
              ))
            end

            it "warns the user about extraneous folders" do
              results = validator.call

              expect(results[:group_folder_contents]).to be_a_warning
              expect(results[:group_folder_contents].message).to eq(i18n_message("nextcloud.unexpected_content"))
            end
          end

          private

          def i18n_message(key, context = {}) = I18n.t("storages.health.connection_validation.#{key}", **context)

          def build_failure(code:, payload:)
            data = StorageErrorData.new(source: "query", payload:)
            error = StorageError.new(code:, data:)
            ServiceResult.failure(result: code, errors: error)
          end
        end
      end
    end
  end
end
