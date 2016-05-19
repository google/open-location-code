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

package com.openlocationcode.android.code;

import com.openlocationcode.android.R;
import com.openlocationcode.android.localities.Locality;
import com.openlocationcode.android.search.SearchContract;

import android.content.Context;
import android.content.res.Resources;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.google.openlocationcode.OpenLocationCode;

public class CodeView extends LinearLayout implements CodeContract.View, SearchContract.TargetView {

    private final TextView mCodeTV;
    private final TextView mLocalityTV;
    private final ImageButton mShareButton;
    private final ImageButton mNavigateButton;
    private final Resources resources;
    private OpenLocationCode lastFullCode;
    private boolean localityValid = false;

    public CodeView(Context context, AttributeSet attrs) {
        super(context, attrs);
        LayoutInflater inflater;
        inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        inflater.inflate(R.layout.code, this, true);
        resources = context.getResources();

        mCodeTV = (TextView) findViewById(R.id.code);
        mLocalityTV = (TextView) findViewById(R.id.locality);
        mShareButton = (ImageButton) findViewById(R.id.shareCodeButton);
        mNavigateButton = (ImageButton) findViewById(R.id.navigateButton);
    }

    public String getCodeAndLocality() {
        if (!localityValid) {
            return lastFullCode.getCode();
        }

        return mCodeTV.getText().toString() + " " + mLocalityTV.getText().toString();
    }

    public OpenLocationCode getLastFullCode() {
        return lastFullCode;
    }

    public ImageButton getShareButton() {
        return mShareButton;
    }

    public ImageButton getNavigateButton() {
        return mNavigateButton;
    }

    @Override
    public void displayCode(OpenLocationCode code) {
        lastFullCode = code;
        // Display the code but remove the first four digits.
        mCodeTV.setText(code.getCode().substring(4));
        // Try to append a locality. If we don't have one, get the unknown string.
        try {
            mLocalityTV.setText(Locality.getNearestLocality(code));
            localityValid = true;
        } catch (Locality.NoLocalityException e) {
            mLocalityTV.setText(resources.getString(R.string.no_locality));
            localityValid = false;
        }
    }

    @Override
    public void showSearchCode(OpenLocationCode code) {
        displayCode(code);
    }
}
