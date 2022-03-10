import App from './App.svelte';

import { register, addMessages, init, getLocaleFromNavigator } from 'svelte-i18n';

import en from '../locale/en.json';
import de from '../locale/de.json';

addMessages('en', en);
addMessages('de', de);

init({
  fallbackLocale: 'en',
  initialLocale: getLocaleFromNavigator(),
});


const app = new App({
	target: document.body,
});

export default app;