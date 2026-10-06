# Window lifecycle requirements

Reported: settings/management and close actions intermittently leave a blank or black window after bilingual support was added.

- Preserve the existing English/Japanese implementation and user data.
- Each settings/statistics manager owns at most one reusable window.
- Header Close, Escape, and native title-bar close must dismiss the same window; reopening shows populated content.
- Language changes update both content and titles without introducing another window.
- Match native content dimensions to the SwiftUI root dimensions.
- Validate repeated dismissal/reopening with regression tests, release build, and installed-app interaction.

- Keep the settings header/Close visible; group settings into Timer, App, Calendar and Categories tabs.

- Editing a category must open the editor with that category populated on the first attempt.

- The Categories settings tab must allow adding a category directly.
