# Frontend

The frontend uses a Svelte/Node.JS stack. See README.svelte.md for details.

Files/Folders:  
`locale/` - i18n files  
`src/App.svelte` - Main page include the definition of drinks  
`src/Order-Overview.svelte` - Page for retrieving and displaying all orders  
`src/store.js` - Variables saved in browsers local storage  
`public/` - Files and images which will be directly served to clients  

## ENV variables

Note that the Dockerfile is set up in a way, that it will only update ENVs on docker build, not on docker run.

`BACKENDURL` Set the backendurl (default: http://exoscale-order-backend.cldsvc.io)
