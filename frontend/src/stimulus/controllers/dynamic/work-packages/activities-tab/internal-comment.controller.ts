/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';
import { renderStreamMessage } from '@hotwired/turbo';
import type IndexController from './index.controller';

export default class InternalCommentController extends Controller {
  static targets = ['internalCheckbox', 'formContainer', 'learnMoreLink'];
  static outlets = ['work-packages--activities-tab--index'];
  static classes = ['highlight', 'hidden'];

  static values = {
    isInternal: { type: Boolean, default: false },
  };

  declare readonly internalCheckboxTarget:HTMLInputElement;
  declare readonly formContainerTarget:HTMLElement;
  declare readonly learnMoreLinkTarget:HTMLAnchorElement;
  declare readonly workPackagesActivitiesTabIndexOutlet:IndexController;
  declare readonly highlightClass:string;
  declare readonly hiddenClass:string;

  declare isInternalValue:boolean;

  onSubmitEnd(_event:CustomEvent):void {
    this.toggleInternal();
  }

  toggleInternal():void {
    const isChecked = this.internalCheckboxTarget.checked;

    this.formContainerTarget.classList.toggle(this.highlightClass, isChecked);
    this.toggleLearnMoreLink(isChecked);
    this.isInternalValue = isChecked;

    if (isChecked) {
      void this.sanitizeInternalMentions();
    }
  }

  private toggleLearnMoreLink(isChecked:boolean):void {
    if (this.workPackagesActivitiesTabIndexOutlet.isMobile()) return; // hidden on mobile

    this.learnMoreLinkTarget.classList.toggle(this.hiddenClass, !isChecked);
  }

  private async sanitizeInternalMentions():Promise<void> {
    if (this.ckEditorInstance) {
      const editorData = this.ckEditorInstance.getData({ trim: false });
      if (editorData.length === 0) return;

      const sanitizePath = `/work_packages/${this.workPackagesActivitiesTabIndexOutlet.workPackageIdValue}/activities/sanitize_internal_mentions`;
      const csrfToken = (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement).content;

      try {
        const response = await fetch(sanitizePath, {
          method: 'POST',
          body: JSON.stringify({ journal: { notes: editorData } }),
          headers: {
            'X-CSRF-Token': csrfToken,
            'Content-Type': 'application/json',
          },
        });

        const sanitizedNotesResponse = await response.text();

        if (response.ok) {
          this.ckEditorInstance.setData(sanitizedNotesResponse);
        } else {
          renderStreamMessage(sanitizedNotesResponse);
          throw new Error(`Failed to sanitize internal mentions. Response status: ${response.status}`);
        }
      } catch (error) {
        console.error(error);
      }
    }
  }

  private get ckEditorInstance() {
    return this.workPackagesActivitiesTabIndexOutlet.getCkEditorInstance();
  }
}
