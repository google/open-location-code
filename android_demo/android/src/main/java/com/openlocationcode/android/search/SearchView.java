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

import com.openlocationcode.android.main.MainActivity;
import com.openlocationcode.android.R;


import android.content.Context;
import android.os.Build.VERSION;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.AttributeSet;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView.OnDismissListener;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.List;

import com.google.openlocationcode.OpenLocationCode;

public class SearchView extends FrameLayout implements SearchContract.SourceView, TextWatcher {

    private SearchContract.ActionsListener mListener;

    private FrameLayout mFocusLayerView;

    private AutoCompleteEditor mSearchET;

    private ImageView mCancelButton;

    private ArrayAdapter<String> mSuggestionsAdapter;

    private boolean mEditFieldFocused;

    public SearchView(Context context, AttributeSet attrs) {
        super(context, attrs);
        LayoutInflater inflater;
        inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        inflater.inflate(R.layout.search, this, true);

        initUI();
    }

    private void initUI() {
        mFocusLayerView = (FrameLayout) findViewById(R.id.focusLayer);
        mSearchET = (AutoCompleteEditor) findViewById(R.id.searchET);
        mSearchET.addTextChangedListener(this);
        mSuggestionsAdapter =
                new ArrayAdapter<>(
                        getContext(),
                        android.R.layout.simple_dropdown_item_1line,
                        new ArrayList<String>());
        mSearchET.setAdapter(mSuggestionsAdapter);
        mSearchET.setOnItemClickListener(new OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                InputMethodManager imm =
                        (InputMethodManager) getContext().getSystemService(
                                Context.INPUT_METHOD_SERVICE);
                imm.hideSoftInputFromWindow(mFocusLayerView.getWindowToken(), 0);
                mSearchET.clearFocus();
                // searchCode stops listening to map drags if the search string was valid.
                mListener.searchCode(getSearchString());
            }
        });

        mCancelButton = (ImageView) findViewById(R.id.cancel);
        mCancelButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mSearchET.setText("");
                // When the cancel button is pressed, start listening to map drags again.
                MainActivity.getMainPresenter().getMapActionsListener().startUpdateCodeOnDrag();
            }
        });

        mSearchET.setImeBackListener(this);

        mSearchET.setOnFocusChangeListener(new OnFocusChangeListener() {
            @Override
            public void onFocusChange(View v, boolean hasFocus) {
                mEditFieldFocused = hasFocus;
            }
        });

        mSearchET.setOnEditorActionListener(
                new OnEditorActionListener() {
                    @Override
                    public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                        if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                            InputMethodManager imm =
                                    (InputMethodManager) getContext()
                                            .getSystemService(Context.INPUT_METHOD_SERVICE);
                            imm.hideSoftInputFromWindow(mFocusLayerView.getWindowToken(), 0);
                            mSearchET.clearFocus();
                            mListener.searchCode(getSearchString());
                            return true;
                        }
                        return false;
                    }
                });

        if (VERSION.SDK_INT >= 17) {
            mSearchET.setOnDismissListener(
                    new OnDismissListener() {
                        @Override
                        public void onDismiss() {
                            mFocusLayerView.setAlpha(0f);
                        }
                    });
        }

        mFocusLayerView.setOnTouchListener(
                new OnTouchListener() {
                    @Override
                    public boolean onTouch(View v, MotionEvent event) {
                        if (mEditFieldFocused) {
                            InputMethodManager imm =
                                    (InputMethodManager) getContext()
                                            .getSystemService(Context.INPUT_METHOD_SERVICE);
                            imm.hideSoftInputFromWindow(mFocusLayerView.getWindowToken(), 0);
                            mSearchET.clearFocus();
                        }
                        return false;
                    }
                });

    }

    private String getSearchString() {
        return mSearchET.getText().toString().trim();
    }

    @Override
    public void imeBackHandler() {
        mSearchET.setText("");
        mSearchET.clearFocus();
    }

    @Override
    public void setActionsListener(SearchContract.ActionsListener listener) {
        mListener = listener;
    }

    @Override
    public void showSuggestions(List<String> suggestions) {
        mSuggestionsAdapter.clear();
        mSuggestionsAdapter.addAll(suggestions);
        mSuggestionsAdapter.notifyDataSetChanged();
    }

    @Override
    public void showInvalidCode() {
        Toast.makeText(
                getContext(),
                getResources().getString(R.string.search_invalid),
                Toast.LENGTH_LONG)
                .show();
    }

    @Override
    public void showEmptyCode() {
        Toast.makeText(
                getContext(),
                getResources().getString(R.string.search_empty),
                Toast.LENGTH_LONG)
                .show();
    }

    @Override
    public void setText(String searchText) {
        if (searchText != null && searchText.length() > 0) {
            mSearchET.setText(searchText);
            mCancelButton.setVisibility(View.VISIBLE);
        }
    }

    @Override
    public void beforeTextChanged(CharSequence s, int start, int count, int after) {
        // Not required
    }

    @Override
    public void onTextChanged(CharSequence s, int start, int before, int count) {
        // Show/hide cancel search button
        if (s.length() > 0) {
            mCancelButton.setVisibility(View.VISIBLE);
        } else {
            mCancelButton.setVisibility(View.GONE);
            // When the cancel button is removed, start listening to map drags again.
            MainActivity.getMainPresenter().getMapActionsListener().startUpdateCodeOnDrag();
        }

        // Show autocomplete if:
        // - code of format XXXX+XXX is entered
        // - a space is typed after at least 7 characters (eg after a XXXX+XX code)
        if ((s.length() >= 8 && OpenLocationCode.isValidCode(s.toString()))
                || (s.length() > 7 && s.charAt(s.length() - 1) == ' ')) {
            mListener.getSuggestions(s.subSequence(0, 8).toString());
            mFocusLayerView.setAlpha(0.15f);
        }
    }

    @Override
    public void afterTextChanged(Editable s) {
        // Not required
    }
}
