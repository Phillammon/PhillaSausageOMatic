
function processRelayReply(reply)
{
	document.open("text/html");
	document.write(reply);
	document.close();
}

async function postFormRequests(requestList) {
	await new Promise((resolve) => setTimeout(resolve, 100));
	var requestData = requestList.shift();
	var request = new XMLHttpRequest();
	request.onreadystatechange = function(response) {if (request.readyState == 4) { if (request.status == 200) {if (requestList.length > 0) {postFormRequests(requestList);} else {processRelayReply(request.responseText);}}}} 
	request.open("POST", requestData.url);
	request.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	request.send(requestData.data);
}

async function grindAndPump(meatPaste, sausage, pwd) {
	var requestList = [];
	if (meatPaste > 0) {
		requestList.push({"url": "craft.php", "data": "action=makepaste&whichitem=25&qty=" + meatPaste +"&pwd=" + pwd})
		requestList.push({"url": "choice.php", "data": "whichchoice=1339&iid=25&option=1&qty=" + meatPaste +"&pwd=" + pwd})
	}
	for (i=0;i < sausage; i++) {
		requestList.push({"url": "choice.php", "data": "whichchoice=1339&option=2&pwd=" + pwd})
	}
	await postFormRequests(requestList);
}