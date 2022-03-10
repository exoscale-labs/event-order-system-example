import { writable } from "svelte/store";

function uuidv4() {
    return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
      (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
    );
  }

// stores some variables to browsers local storage

export const username = writable(window.localStorage.getItem('username') || "");
username.subscribe((value) => localStorage.setItem('username', value));

export const userid = writable(window.localStorage.getItem('userid') || uuidv4());
userid.subscribe((value) => localStorage.setItem('userid', value));

export const drinkid = writable(parseInt(window.localStorage.getItem('drinkid')) || 0);
// update localstorage
drinkid.subscribe((value) => localStorage.setItem('drinkid', value));
