
function processRelayReply(reply)
{
	document.open("text/html");
	document.write(reply);
	document.close();
}

function postFormRequest(page_url, parameters) {
	var formData = new FormData();
	
	for (var key in parameters)
	{
		formData.append(key, parameters[key]);
		console.log(key);
		console.log(formData.get(key));
	}
	var request = new XMLHttpRequest();
	request.onreadystatechange = function() { processRelayReply(request.responseText);} 
	request.open("POST", page_url);
	request.send(formData);
}

function makePaste(amount, pwd) {
		postFormRequest("craft.php", {
			"action": "makepaste",
			"pwd": pwd,
			"qty": amount,
			"whichitem": 25
		});
}

function grindPaste(amount, pwd) {
		postFormRequest("craft.php", {
			"pwd": pwd,
			"action": "makepaste",
			"qty": amount,
			"whichitem": 25
		});
}

function makeSausage(amount, pwd) {
	if (amount <= 1) {
		postFormRequest("choice.php", {
			"pwd": pwd,
			"whichchoice": "1339",
			"option": "2",
		});
	} 
	else {
		postFormRequest("choice.php", {
			"pwd": pwd,
			"whichchoice": "1339",
			"option": "2",
		});
		makeSausage(amount-1, pwd);
	}
}


function grindAndPump(meatPaste, sausage, pwd) {
	if (meatPaste > 0 && sausage > 0) {
		makePaste(meatPaste, pwd);
	}
	else if (meatPaste > 0) {
		makePaste(meatPaste, pwd);
	}
	else if (sausage > 0) {
		makeSausage(sausage, pwd);
	}
}