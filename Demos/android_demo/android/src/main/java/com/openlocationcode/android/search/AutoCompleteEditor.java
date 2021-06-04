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

import android.content.Context;
import android.util.AttributeSet;
import android.view.KeyEvent;
import android.widget.AutoCompleteTextView;

/**
 * Super class of AutoCompleteTextView that allows detection of the soft keyboard dismissal.
 */
public class AutoCompleteEditor extends AutoCompleteTextView {

    private com.openlocationcode.android.search.SearchContract.SourceView imeBackListener;

    public AutoCompleteEditor(Context context) {
        super(context);
    }

    public AutoCompleteEditor(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public void setImeBackListener(SearchContract.SourceView imeBackListener) {
        this.imeBackListener = imeBackListener;
    }

    @Override
    public boolean onKeyPreIme(int keyCode, KeyEvent event) {
        if (event.getKeyCode() == KeyEvent.KEYCODE_BACK
                && event.getAction() == KeyEvent.ACTION_UP) {
            if (imeBackListener != null) {
                imeBackListener.imeBackHandler();
            }
        }

        return super.onKeyPreIme(keyCode, event);
    }
}

