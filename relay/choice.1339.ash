script "PhillaSausageOMatic";
notify Phillammon;

// To all who look upon this, I apologise deeply. this was my first foray into learning .ASH scripting
// and with it come some odd decisions due to being unclear what JS features are and aren't included.
// Good luck.
import "relay/choice.ash";

int roundToNearestMeatPaste(int number) {
   return to_int(ceil(to_float(number)/10.0));
}

int [string] parseSausageString(string pageText) {
	int [string] values = {
		"currMeat":0,
		"nextCost":0,
		"currCasings":0,
		"currSausages":0,
		"meatToNext":0,
		"meatToCasings":0,
		"meatToAll":0,
		"casingsCost":0,
		"allCost":0,
		"remainingSausages":0,
		"pumpableSausages":0,
		"dangerousPumpAndGrindSausages":0,
		"dangerousPumpAndGrindMeat":0
	};
	matcher currMeat = create_matcher("(er reads \")(\\d+)(\" uni)" , pageText);
	if (currMeat.find()) {
		values["currMeat"] = to_int(currMeat.group(2));
	}
	matcher currCost = create_matcher("(of the )([\\d\,]+)( required )" , pageText);
	if (currCost.find()) {
		values["nextCost"] = to_int(currCost.group(2));
	}
	matcher currCasings = create_matcher("(have )([\\d+\,]+)( magic)" , pageText);
	if (currCasings.find()) {
		values["currCasings"] = to_int(currCasings.group(2));
	}
	values["currSausages"] = values["nextCost"]/111-1;
	values["meatToNext"] = max(values["nextCost"] - values["currMeat"], 0);
	int meatSoFar = values["currSausages"]*(values["currSausages"]+1)/2*111;
	values["casingsCost"] = (values["currCasings"]+values["currSausages"]) * (values["currCasings"]+values["currSausages"]+1)/2*111 - meatSoFar;
	values["meatToCasings"] = max(values["casingsCost"] - values["currMeat"], 0);
	values["allCost"] = max(30636 - meatSoFar, 0);
	values["meatToAll"] = max(values["allCost"] - values["currMeat"], 0);
	values["remainingSausages"] = max(23 - values["currSausages"], 0);
	boolean flag = true;
	int reqdMeat = values["nextCost"];
	int possibleSausages = 0;
	while (flag) {
		if (reqdMeat < values["currMeat"] && (possibleSausages < values["currCasings"])) {
			possibleSausages = possibleSausages + 1;
			reqdMeat = reqdMeat + values["nextCost"] + possibleSausages * 111;
		}
		else {
			flag = false;
		}
	}
	values["pumpableSausages"] = possibleSausages;
	reqdMeat = values["nextCost"];
	possibleSausages = 0;
	flag = true;
	while (flag) {
		if (reqdMeat < (values["currMeat"] + my_meat()) && (possibleSausages < values["currCasings"])) {
			possibleSausages = possibleSausages + 1;
			reqdMeat = reqdMeat + values["nextCost"] + possibleSausages * 111;
		}
		else {
			flag = false;
		}
	}
	values["dangerousPumpAndGrindSausages"] = possibleSausages;
	values["dangerousPumpAndGrindMeat"] = reqdMeat - values["currMeat"] - values["nextCost"] - possibleSausages * 111;
	values["meatPasteToNext"] = roundToNearestMeatPaste(values["meatToNext"]);
	values["meatPasteToCasings"] = roundToNearestMeatPaste(values["meatToCasings"]);
	values["meatPasteToAll"] = roundToNearestMeatPaste(values["meatToAll"]);
	values["dangerousPumpAndGrindMeatPaste"] = roundToNearestMeatPaste(values["dangerousPumpAndGrindMeat"]);
	return values;
}

string [int] getSausageDisableStates(int [string] values) {
	string [int] states = {
		0:"",
		1:"",
		2:"",
		3:"",
		4:"",
		5:"",
		6:"",
		7:"",
		8:"",
		9:"",
		10:"",
		11:"disabled",
	}; //you would not believe how much I wish ash had ternary operations right now
	if (my_meat() < values["meatPasteToNext"]*10 || values["meatToNext"] < 1) {
		states[0] = "disabled";
	}
	if (my_meat() < values["meatPasteToCasings"]*10 || values["meatToCasings"] < 1) {
		states[1] = "disabled";
	}
	if (my_meat() < values["meatPasteToAll"]*10 || values["meatToAll"] < 1) {
		states[2] = "disabled";
	}
	if (values["currMeat"] < values["nextCost"] || values["currCasings"] < 1) {
		states[3] = "disabled";
	}
	if (values["currMeat"] < values["casingsCost"] || values["currCasings"] < values["remainingSausages"]) {
		states[4] = "disabled";
	}
	if (my_meat() < values["meatPasteToNext"]*10 || values["currCasings"] < 1) {
		states[6] = "disabled";
	}
	if (my_meat() < values["meatPasteToCasings"]*10) {
		states[7] = "disabled";
	}
	if (my_meat() < values["meatPasteToAll"]*10 || values["currCasings"] < values["remainingSausages"]) {
		states[8] = "disabled";
	}
	if (my_meat() < 30640) {
		states[9] = "disabled";
	}
	return states;
}

string extractForm(string pageText) {
	matcher grinder = create_matcher("(<form method=\"post\".+?<\/form>)", pageText);
	if (grinder.find()) {
		return grinder.group(1);
	}
	return "";
}

void main(string page_text_encoded) {
	buffer page_buffer;
	int [string] values = parseSausageString(page_text_encoded.choiceOverrideDecodePageText());
	string [int] disableStates = getSausageDisableStates(values);
	page_buffer.append("<script type=\"text/javascript\" src=\"phillaSausageOMatic.js\"></script>");
	page_buffer.append("<b>WELCOME TO KRAMCO</b>");
	page_buffer.append("<br /><br />");
	page_buffer.append("<b>STATUS:</b>");
	page_buffer.append("<br />");
	page_buffer.append("Current meat level: " + to_string(values["currMeat"]) + " meat");
	page_buffer.append("<br />");
	page_buffer.append("Current casings: " + to_string(values["currCasings"]));
	page_buffer.append("<br />");
	page_buffer.append("Sausages made today: " + to_string(values["currSausages"]));
	page_buffer.append("<br />");
	page_buffer.append("Meat required for next sausage: " + to_string(values["nextCost"]) + " meat");
	if (values["meatToNext"] > 0) {
		page_buffer.append(" (need " + to_string(values["meatToNext"]) + " more)");
	}
	page_buffer.append("<br />");
	page_buffer.append("Meat required for all casings: " + to_string(values["casingsCost"]) + " meat");
	if (values["meatToCasings"] > 0) {
		page_buffer.append(" (need " + to_string(values["meatToCasings"]) + " more)");
	}
	page_buffer.append("<br />");
	page_buffer.append("Meat required for all of today's sausages: " + to_string(values["allCost"]) + " meat");
	if (values["meatToAll"] > 0) {
		page_buffer.append(" (need " + to_string(values["meatToAll"]) + " more)");
	}
	page_buffer.append("<br />");
	page_buffer.append("<br />");
	page_buffer.append("<table style=\"text-align:center; border:0px;\">");
	
	page_buffer.append("<tr><td></td><td><b>GRIND<b></td><td></td></tr>");
	page_buffer.append("<td><button " + disableStates[0] + " onClick=\"grindAndPump(" + to_string(values["meatPasteToNext"]) + ", 0, \'" + my_hash() + "\');\">Fill to next sausage (" + to_string(values["meatPasteToNext"] * 10) + " meat)</button></td>");
	page_buffer.append("<td><button " + disableStates[1] + " onClick=\"grindAndPump(" + to_string(values["meatPasteToCasings"]) + ", 0, \'" + my_hash() + "\');\">Fill for all casings (" + to_string(values["meatPasteToCasings"] * 10) + " meat)</button></td>");
	page_buffer.append("<td><button " + disableStates[2] + " onClick=\"grindAndPump(" + to_string(values["meatPasteToAll"]) + ", 0, \'" + my_hash() + "\');\">Fill for today's sausages (" + to_string(values["meatPasteToAll"] * 10) + " meat)</button></td>");
	
	page_buffer.append("<tr><td></td><td><b>PUMP<b></td><td></td></tr>");
	page_buffer.append("<td><button " + disableStates[3] + " onClick=\"grindAndPump(0, 1, \'" + my_hash() + "\');\">Pump a sausage (1 sausage)</button></td>");
	page_buffer.append("<td><button " + disableStates[4] + " onClick=\"grindAndPump(0, " + to_string(values["currCasings"]) + ", \'" + my_hash() + "\');\">Pump all casings (" + to_string(values["currCasings"]) + " sausages)</button></td>");
	page_buffer.append("<td><button " + disableStates[5] + " onClick=\"grindAndPump(0, " + to_string(values["pumpableSausages"]) + ", \'" + my_hash() + "\');\">Pump as many sausages as possible (" + to_string(values["pumpableSausages"]) + " sausages)</button></td>");
	
	page_buffer.append("<tr><td></td><td><b>GRIND AND PUMP<b></td><td></td></tr>");
	page_buffer.append("<td><button " + disableStates[6] + " onClick=\"grindAndPump(" + to_string(values["meatPasteToNext"]) + ", 1, \'" + my_hash() + "\');\">Grind and pump a sausage (" + to_string(values["meatPasteToNext"] * 10) + " meat, 1 sausage)</button></td>");
	page_buffer.append("<td><button " + disableStates[7] + " onClick=\"grindAndPump(" + to_string(values["meatPasteToCasings"]) + ", " + to_string(values["currCasings"]) + ", \'" + my_hash() + "\');\">Grind and pump all casings (" + to_string(values["meatPasteToCasings"] * 10) + " meat, " + to_string(values["currCasings"]) + " sausages)</button></td>");
	page_buffer.append("<td><button " + disableStates[8] + " onClick=\"grindAndPump(" + to_string(values["meatPasteToNext"]) + ", " + to_string(values["remainingSausages"]) + ", \'" + my_hash() + "\');\">Grind and pump today's sausages (" + to_string(values["meatPasteToAll"] * 10) + " meat, " + to_string(values["remainingSausages"]) + " sausages)</button></td>");
	
	page_buffer.append("<tr><td></td><td><b>DANGEROUS BUTTONS (YOU HAVE BEEN WARNED)<b></td><td></td></tr>");
	page_buffer.append("<td><button " + disableStates[9] + " onClick=\"grindAndPump(3064, 0, \'" + my_hash() + "\');\">Preload an entire day's worth of meat (30640 meat)</button></td>");
	page_buffer.append("<td><button " + disableStates[10] + " onClick=\"grindAndPump(" + to_string(values["dangerousPumpAndGrindMeatPaste"]) + ", " + to_string(values["dangerousPumpAndGrindSausages"]) + ", \'" + my_hash() + "\');\">Grind and pump as many sausages as possible (" + to_string(values["dangerousPumpAndGrindMeatPaste"] * 10) + " meat, " + to_string(values["dangerousPumpAndGrindSausages"]) + " sausages)</button></td>");
	page_buffer.append("<td><button " + disableStates[11] + ">!!! GRIND ALL EVERYTHING !!!</button></td>");
	
	page_buffer.append("</table>");
	page_buffer.append("<br /><br />");
	page_buffer.append("<b>Or just grind stuff manually:</b>");
	page_buffer.append("<br />");
	
	page_buffer.append(extractForm(page_text_encoded.choiceOverrideDecodePageText()));
	write(page_buffer);
}