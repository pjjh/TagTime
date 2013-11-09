package bsoule.tagtime;

import java.util.Arrays;

import android.content.Intent;
import android.os.Bundle;
import android.os.Vibrator;
import android.preference.CheckBoxPreference;
import android.preference.ListPreference;
import android.preference.Preference;

import com.actionbarsherlock.app.ActionBar;
import com.actionbarsherlock.app.SherlockPreferenceActivity;
import com.actionbarsherlock.view.MenuItem;

public class Preferences extends SherlockPreferenceActivity {

	private ActionBar mAction;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		addPreferencesFromResource(R.xml.preferences);

		mAction = getSupportActionBar();
		mAction.setHomeButtonEnabled(true);
		mAction.setIcon(R.drawable.tagtime_03);


		ListPreference order = (ListPreference) findPreference("sortOrderPref");

		order.setSummary(order.getEntry());

		// Set the summary text of the order when it changes
		order.setOnPreferenceChangeListener(new Preference.OnPreferenceChangeListener() {
			public boolean onPreferenceChange(Preference preference, Object newValue) {
				ListPreference x = (ListPreference) preference;
				int index = Arrays.asList(x.getEntryValues()).indexOf(newValue);
				preference.setSummary(x.getEntries()[index]);
				return true;
			}
		});

		CheckBoxPreference vibrate = (CheckBoxPreference) findPreference("pingVibrate");

		vibrate.setOnPreferenceChangeListener(new Preference.OnPreferenceChangeListener() {
			public boolean onPreferenceChange(Preference preference, Object newValue) {
				if ((Boolean) newValue) {
					Vibrator v = (Vibrator) getSystemService(VIBRATOR_SERVICE);
					v.vibrate(25);
				}
				return true;
			}
		});

	}
	
	/** Handles menu item selections */
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// Handle item selection
		switch (item.getItemId()) {
		case android.R.id.home:
			// app icon in action bar clicked; go home
			Intent intent = new Intent(this, TPController.class);
			intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
			startActivity(intent);
			finish();
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}

}
