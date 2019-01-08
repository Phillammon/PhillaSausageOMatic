script "PhillaSausageOMatic";
notify Phillammon;

// To all who look upon this, I apologise deeply. this was my first foray into learning .ASH scripting
// and with it come some odd decisions due to being unclear what JS features are and aren't included.
// Good luck.
import "relay/choice.ash";

int roundToNearestMeatPaste(int number) {
   return to_int(ceil(to_float(number)/10.0));
}


int [string] getValuesFromPage(string pageText) {
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

boolean [int] getEnabledButtons(int [string] values) {
	boolean [int] states = {
		0: (my_meat() >= values["meatPasteToNext"]*10 && values["meatToNext"] > 0),
		1: (my_meat() >= values["meatPasteToCasings"]*10 && values["meatToCasings"] > 0),
		2: (my_meat() >= values["meatPasteToAll"]*10 && values["meatToAll"] > 0),
		3: (values["currMeat"] >= values["nextCost"] && values["currCasings"] > 0),
		4: (values["currMeat"] >= values["casingsCost"] && values["currCasings"] > 0),
		5: (values["pumpableSausages"] > 0 && values["currMeat"] >= values["nextCost"]),
		6: (my_meat() >= values["meatPasteToNext"]*10 || values["currCasings"] > 0),
		7: (my_meat() >= values["meatPasteToCasings"]*10 || values["currCasings"] > 0),
		8: (my_meat() >= values["meatPasteToAll"]*10 || values["currCasings"] > values["remainingSausages"] && values["remainingSausages"] > 0),
		9: (my_meat() >= 30640),
		10: (values["currCasings"] > 0 && my_meat() >= values["meatPasteToNext"]*10),
		11: false,
	};
	if (values["currMeat"] < values["nextCost"] || values["currCasings"] < 1) {
		states[5] = false;
	}
	if (my_meat() < values["meatPasteToNext"]*10 || values["currCasings"] < 1) {
		states[6] =  false;
	}
	if (my_meat() < values["meatPasteToCasings"]*10) {
		states[7] = false;
	}
	if (my_meat() < values["meatPasteToAll"]*10 || values["currCasings"] < values["remainingSausages"] || values["remainingSausages"] == 0) {
		states[8] = false;
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

string generatePreamble(int [string] values) {
	buffer preamble;
	preamble.append("<b>WELCOME TO KRAMCO</b>");
	preamble.append("<br /><br />");
	preamble.append("<b>STATUS:</b>");
	preamble.append("<br />");
	preamble.append("Current meat level: " + to_string(values["currMeat"]) + " meat");
	preamble.append("<br />");
	preamble.append("Current casings: " + to_string(values["currCasings"]));
	preamble.append("<br />");
	preamble.append("Sausages made today: " + to_string(values["currSausages"]));
	preamble.append("<br />");
	preamble.append("Meat required for next sausage: " + to_string(values["nextCost"]) + " meat");
	if (values["meatToNext"] > 0) {
		preamble.append(" (need " + to_string(values["meatToNext"]) + " more)");
	}
	preamble.append("<br />");
	preamble.append("Meat required for all casings: " + to_string(values["casingsCost"]) + " meat");
	if (values["meatToCasings"] > 0) {
		preamble.append(" (need " + to_string(values["meatToCasings"]) + " more)");
	}
	preamble.append("<br />");
	preamble.append("Meat required for all of today's sausages: " + to_string(values["allCost"]) + " meat");
	if (values["meatToAll"] > 0) {
		preamble.append(" (need " + to_string(values["meatToAll"]) + " more)");
	}
	return to_string(preamble);	
}

string generateButton(string label, int paste, int sausages, boolean enabled) {
	buffer button;
	button.append("<button");
	if (!enabled) {
		button.append(" disabled");
	}
	button.append(" onClick=\"grindAndPump(" + to_string(paste) + ", " + to_string(sausages) + ", \'" + my_hash() + "\');\">");
	button.append(label);
	if (paste > 0 || sausages > 0) {
		button.append("<br />(");
		if (paste > 0) {
			button.append("Grind " + to_string(paste) + "0 more meat");
			if (sausages > 0) {
				button.append(", then pump " + to_string(sausages)+ " sausage");
			}
		}
		else if (sausages > 0) {
			button.append("Pump " + to_string(sausages)+ " sausage");
		}
		if (sausages > 1) {
			button.append("s");
		}
		button.append(")");
	}
	button.append("</button>");
	return to_string(button);
}

void main(string page_text_encoded) {
	buffer page_buffer;
	int [string] values = getValuesFromPage(page_text_encoded.choiceOverrideDecodePageText());
	boolean [int] enabledButtons = getEnabledButtons(values);
	page_buffer.append("<script type=\"text/javascript\" src=\"phillaSausageOMatic.js\"></script>");
	page_buffer.append(generatePreamble(values));
	page_buffer.append("<br /><br />");
	
	
	page_buffer.append("<table style=\"text-align:center; border:0px;\">");
	
	page_buffer.append("<tr><td></td><td><b>GRIND<b></td><td></td></tr>");
	page_buffer.append("<td>" + generateButton("Grind enough meat for one sausage", values["meatPasteToNext"], 0, enabledButtons[0]) + "</td>");
	page_buffer.append("<td>" + generateButton("Grind enough meat for all casings", values["meatPasteToCasings"], 0, enabledButtons[1]) + "</td>");
	page_buffer.append("<td>" + generateButton("Grind enough meat for today's sausages", values["meatPasteToAll"], 0, enabledButtons[2]) + "</td>");
	
	page_buffer.append("<tr><td></td><td><b>PUMP<b></td><td></td></tr>");
	page_buffer.append("<td>" + generateButton("Pump one sausage", 0, 1, enabledButtons[3]) + "</td>");
	page_buffer.append("<td>" + generateButton("Pump all casings", 0, values["currCasings"], enabledButtons[4]) + "</td>");
	page_buffer.append("<td>" + generateButton("Pump as many sausages as possible",  0, values["pumpableSausages"], enabledButtons[5]) + "</td>");
	
	page_buffer.append("<tr><td></td><td><b>GRIND AND PUMP<b></td><td></td></tr>");
	page_buffer.append("<td>" + generateButton("Grind and pump one sausage", values["meatPasteToNext"], 1, enabledButtons[6]) + "</td>");
	page_buffer.append("<td>" + generateButton("Grind and pump all casings", values["meatPasteToCasings"], values["currCasings"], enabledButtons[7]) + "</td>");
	page_buffer.append("<td>" + generateButton("Grind and pump today's sausages", values["meatPasteToAll"], values["remainingSausages"], enabledButtons[8]) + "</td>");
	
	page_buffer.append("<tr><td></td><td><b>DANGEROUS BUTTONS (YOU HAVE BEEN WARNED)<b></td><td></td></tr>");
	page_buffer.append("<td>" + generateButton("Preload an entire day's worth of meat", 3064, 0, enabledButtons[9]) + "</td>");
	page_buffer.append("<td>" + generateButton("Grind and pump as many sausages as possible", values["dangerousPumpAndGrindMeatPaste"], values["dangerousPumpAndGrindSausages"], enabledButtons[10]) + "</td>");
	page_buffer.append("<td><button disabled>!!! GRIND ALL EVERYTHING !!!</button></td>");
	
	page_buffer.append("</table>");
	page_buffer.append("<br /><br />");
	page_buffer.append("<b>Or just grind stuff manually:</b>");
	page_buffer.append("<br />");
	
	page_buffer.append(extractForm(page_text_encoded.choiceOverrideDecodePageText()));
	write(page_buffer);
}