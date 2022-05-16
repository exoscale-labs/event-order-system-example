<script>
	import { NotificationDisplay, notifier } from '@beyonk/svelte-notifications'
	import { userid, username, drinkid } from './store.js';
	import { fade, fly } from 'svelte/transition';
	import { _ } from 'svelte-i18n'

	import OrderOverview from './Order-Overview.svelte';

	import io from 'socket.io-client'

	const socket = io(process.env.backendurl);

	let drinks = [
		{ id: 1, name: $_("drinks.1"), img: 'img/coffee.jpeg' },
		{ id: 2, name: $_("drinks.2"), img: 'img/redwine.jpeg' },
		{ id: 3, name: $_("drinks.3"), img: 'img/whitewine.jpeg' },
		{ id: 4, name: $_("drinks.4"), img: 'img/beer.jpeg' },
	];

	//// ------------ Drink selection ------------
	let errorInput = false;
	function selectDrink(id) {
		if ($username.length < 1) {
			errorInput = true;

			setTimeout(function() {
				errorInput = false;
			}, 1000);
		} else {
			var url = new URL(process.env.backendurl + '/drink/' + id);

			var params = {nickname: $username, userid: $userid};
			url.search = new URLSearchParams(params).toString();

			fetch(url)
			.then(response => {
				if (response.status == 200) {
					notifier.success($_("success"));
					drinkid.set(id);
				} else {
					notifier.danger('Error ' + response.status);
					console.log(response);
				}
			})
			.catch(error => {
				console.log(error);
				notifier.danger('Error ' + error);
				return [];
			});
		}
	}

	//// ------------ Live Ticker ------------
	let messages = [
	];
	let counter = 0;
	socket.on('ordernotification', (data) => {
		var drinkname = drinks.find(item => item.id === parseInt(data.drinkid)).name;
		messages.push({key: counter++, data: $_("ordered-message", { values: { name: data.nickname, drink: drinkname } })});
		if (messages.length > 10)
			messages.shift();
		messages = messages;


		console.log(data);
	})

	// Is currently in bar mode?
	const urlParams = new URLSearchParams(window.location.search);
    const isBar = urlParams.has('bar');
	const isQR = urlParams.has('qr');

</script>

<NotificationDisplay />

<div class="header">
	<img src="img/exoscale-RGB-logo-white-transparentBG.png" alt="Exoscale Logo">
</div>

{#if isBar}
<OrderOverview drinks="{drinks}"></OrderOverview>
{:else}
<main>
	<h1>{$_("hello", { values: { name: $username } })}</h1>
	<p>{$_("welcome-notice")}</p>

	<div class="step">
		<h2>{$_("step1")}</h2>
		<input class="{errorInput === true ? 'bounce' : ''}" maxlength=30 placeholder="{$_("nickname")}" bind:value={$username}>
		<p class="notice">{$_("step1-notice")}</p>
	</div>

	<div class="step">
		<h2>{$_("step2")}</h2>

		<div class="drink-container">
		{#each drinks as drink}
			<button class="drink {$drinkid === drink.id ? "drink-selected" : "test"}" 
					on:click="{() => selectDrink(drink.id)}">
				<img src={drink.img} alt="{drink.name}">
				<div class="drink-description">
					<p>{drink.name}</p>
				</div>
			</button>
		{/each}
		</div>
		<p class="notice">{$_("step2-notice")}</p>
	</div>
	
	<div in:fade class="stream">
		{#each messages as message, i (message.key)}
		<div class="stream-element" in:fly="{{ y: 150, duration: 1500 }}" out:fade="{{ duration: 200 }}">{message.data}</div>
		{/each}
	</div>

	{#if isQR}
	<div>
		<img src=img/qr-code.png alt=qrcode width=400px>
	</div>
	{/if}
</main>
{/if}

<style>
    :root {
		--exoscale-red: #da291c;
		--exoscale-blue: #9cb6d8;
		--border-color: #e5e7eb;
		--border-color-selected: #9cb6d8; 
	}

	.header {
		height: 200px;
		background-color: #da291c;
		background-image: url(/img/pattern-bg-03.svg),linear-gradient(120deg,#da291c,#d5281b 30%,#d5281b 70%,#da291c);
		background-position: 50% 50%;
		background-size: 5000px 5000px, 100% 100%;
		background-repeat: no-repeat;

		display: flex;
		align-items: center;
		justify-content: center;
	}

	.header img {
		width: 40%;
	}

	@media (max-width: 800px) {
		.header img {
			width: 70%;
		}
	}

	main {
		text-align: center;
		margin: 0 auto;

		padding-top: 10px;

		color: #334155;
	}

	h1 {
		color: #ff3e00;
		text-transform: uppercase;
		font-size: 4em;
		font-weight: 100;
	}

	input {
		border-radius: 0.25rem;
		border: 1px solid var(--border-color);
		transition: 0.5s;
	}

	input:focus {
		border: 2px solid var(--border-color-selected);
		outline: none !important;
		transition: 0.5s;
	}

	.notice {
		font-style: italic;
		color: grey;
	}

	.step {
		margin-bottom: 50px;
	}

	.drink-container {
		display: flex;
		flex-direction: row;
		flex-wrap: wrap;
	}

	@media (max-width: 800px) {
		.drink-container {
			flex-direction: column;
			align-items: center;
			justify-content: center;
		}
	}

	.drink {
		display: block;
		flex: 25%;
		padding: 15px;
		height: 125px;
		max-height: 125px;
		width: 350px;
		overflow: hidden;

		border: solid 0.1px #e5e7eb;
		border-radius: 0.75rem;
		background-color: white;

		box-sizing: border-box;

		box-shadow: rgb(255, 255, 255) 0px 0px 0px 0px, rgba(15, 23, 42, 0.05) 0px 0px 0px 1px, rgba(0, 0, 0, 0.1) 0px 10px 15px -3px, rgba(0, 0, 0, 0.1) 0px 4px 6px -4px;

		margin: 20px;
	
		transition: background-color .2s ease-in-out;

		color: rgba(0, 0, 0, 0.85);
	}

	.drink:hover {
		background-color: #f2f2f2;
		cursor: pointer;

		color: rgba(0, 0, 0, 0.85);
	}

	.drink-selected {
		background-color: var(--exoscale-red);
		color: white;
	}

	.drink-selected:hover {
		background-color: var(--exoscale-red);
		color: white;
	}


	.drink img {
		width: auto;
		height: 125px;
		max-height: 125px;
		max-width: 135px;
		float: left;
		margin: -1rem 0 0 -1rem;
	}

	.drink .drink-description {
		overflow: hidden;
		height: 100%;
		display: flex;
		text-align: center;
	}

	.drink .drink-description p {
		margin-left: 1rem;
		text-align: center;
		font-weight: 300;
		font-size: 1.9rem;
		line-height: 1.75rem;
		width: 100%;
	}

	@media (min-width: 640px) {
		main {
			max-width: none;
		}
	}

	.stream {
		padding-bottom: 100px;
		height: 350px;
		color: grey;
		font-weight: 300;
	}

	.stream-element {
		margin-bottom: 10px;
		line-height: 20px;
	}
</style>

