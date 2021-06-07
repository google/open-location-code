/*
 * Copyright 2016 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.openlocationcode.android.search;

import com.google.openlocationcode.OpenLocationCode;

import java.util.List;

/**
 * The contract for the search functionality.
 */
public interface SearchContract {

    /**
     * The contract for a view allowing the user to enter search criteria.
     */
    interface SourceView {

        void showInvalidCode();

        void showEmptyCode();

        void setActionsListener(ActionsListener listener);

        void showSuggestions(List<String> suggestions);

        void imeBackHandler();

        void setText(String text);

    }

    /**
     * The contract for a view displaying the result of the search.
     */
    interface TargetView {

        void showSearchCode(OpenLocationCode code);

    }

    interface ActionsListener {

        boolean searchCode(String code);

        void getSuggestions(String code);

        void setSearchText(String text);

    }

}
