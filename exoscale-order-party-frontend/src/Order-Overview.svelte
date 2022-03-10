<script>
    import { onMount } from 'svelte';
    let orders = [];

    onMount(async () => {
        const response = await fetch(process.env.backendurl + "/orders");
        orders = await response.json();
        console.log(orders);
    });

    export let drinks;


	// Holds table sort state.  Initialized to reflect table sorted by id column ascending.
	let sortBy = {col: "nickname", ascending: true};
	
	$: sort = (column) => {
		
		if (sortBy.col == column) {
			sortBy.ascending = !sortBy.ascending
		} else {
			sortBy.col = column
			sortBy.ascending = true
		}
		
		// Modifier to sorting function for ascending or descending
		let sortModifier = (sortBy.ascending) ? 1 : -1;
		
		let sort = (a, b) => 
			(String(a[column]).toLowerCase() < String(b[column]).toLowerCase()) 
			? -1 * sortModifier 
			: (String(a[column]).toLowerCase() > String(b[column]).toLowerCase()) 
			? 1 * sortModifier 
			: 0;
		
            orders = orders.sort(sort);
	}
</script>

<div id=ordertablecontainer>
    <p>Click on any column to sort</p>
    <table id=ordertable>
        <tr>
            <th on:click={sort("nickname")}>Nickname</th>
            <th on:click={sort("drinkid")}>Order</th>
            <th on:click={sort("time")}>Time</th>
            <th class=align-right>UUID</th>
        </tr>
        {#each orders as order}
        <tr>
            <td>{order.nickname}</td>
            <td>{drinks.find(item => item.id === order.drinkid)?.name || ""}</td>
            <td>{new Date(order.time).toLocaleTimeString()}</td>
            <td class="align-right userid">{order.userid}</td>
        </tr>
        {/each}
    </table>
</div>

<style>
#ordertablecontainer {
    margin: 20px;
}

#ordertable {
    width: 100%;
    border-collapse: collapse;
}

#ordertable td, #ordertable th {
    border: 1px solid #ddd;
    padding: 8px;
}

#ordertable tr:nth-child(even){background-color: #f2f2f2;}

#ordertable tr:hover {background-color: #ddd;}

#ordertable th {
    padding-top: 12px;
    padding-bottom: 12px;
    text-align: left;
    background-color: #aa0404;
    color: white;
}

#ordertable .align-right {
    text-align: right;
}

#ordertable .userid {
    font-size: 0.65em;
}
</style>

