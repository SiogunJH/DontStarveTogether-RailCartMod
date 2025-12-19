name = "Rail Cart - Updated"
description = [[
Add rail carts to the game!

Build tracks, hop in, and ride!

Made by:
> Gleenus - main scripting and english translation
> Catherine - art
> KIT - crash fixes and chinese translation
> SiogunJH - project reorganization and reupload, along with polish language 

]]
author = "Gleenus and other"
version = "1.070"
forumthread = ""
api_version = 10
dst_compatible = true

all_clients_require_mod = true
client_only_mod = false

server_filter_tags = {"gcmods"}

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

----------------------------
-- Configuration settings --
----------------------------


configuration_options = 
{
	{
		name = "RAILCART_LANGUAGE",
		label = "Language",
		hover = "Select mod language",
		options =	
		{
			{description = "English", data = "en"},
			{description = "Polski", data = "pl"},
			{description = "中文", data = "zh"},
		},
		default = "en",
	},
	{
		name = "RAILCART_CRAFTAMOUNT",
		label = "Tracks per craft",
		hover = "Number of tracks received per craft.\nDefault: 6",
		options =	
		{
			{description = " 1", data =  1},
			{description = " 2", data =  2},
			{description = " 3", data =  3},
			{description = " 4", data =  4},
            {description = " 5", data =  5},
			{description = " 6", data =  6},
			{description = " 8", data =  8},
			{description = "10", data = 10},
			{description = "12", data = 12},
			{description = "15", data = 15},
			{description = "20", data = 20},
			{description = "30", data = 30},
			{description = "60", data = 60},
		},
		default = 6,
	},
	
	{
		name = "RAILCART_SPEEDUP",
		label = "Acceleration factor",
		hover = "Changes the Rail Cart acceleration.\nDefault: 1.00",
		options =	
		{
			{description = "0.10", data =  0.1},
			{description = "0.25", data = 0.25},
			{description = "0.50", data =  0.5},
			{description = "0.75", data =  0.75},
            {description = "1.00", data =  1},
			{description = "1.25", data =  1.25},
			{description = "1.50", data = 1.5},
			{description = "1.75", data = 1.75},
			{description = "2.00", data = 2},
			{description = "2.50", data = 2.5},
			{description = "3.00", data = 3},
		},
		default = 1,
	},
	
	{
		name = "RAILCART_DAMPING",
		label = "Friction factor",
		hover = "Changes the Rail Cart friction.\nDefault: 1.00",
		options =	
		{
			{description = "0.00", data =  0.0},
			{description = "0.25", data = 0.25},
			{description = "0.50", data =  0.5},
			{description = "0.75", data =  0.75},
            {description = "1.00", data =  1},
			{description = "1.25", data =  1.25},
			{description = "1.50", data = 1.5},
			{description = "1.75", data = 1.75},
			{description = "2.00", data = 2},
			{description = "2.50", data = 2.5},
			{description = "3.00", data = 3},
		},
		default = 1,
	},
	
	{
		name = "RAILCART_BRAKING",
		label = "Braking factor",
		hover = "Changes the Rail Cart braking power.\nDefault: 1.00",
		options =	
		{
			{description = "0.10", data =  0.1},
			{description = "0.25", data = 0.25},
			{description = "0.50", data =  0.5},
			{description = "0.75", data =  0.75},
            {description = "1.00", data =  1},
			{description = "1.25", data =  1.25},
			{description = "1.50", data = 1.5},
			{description = "1.75", data = 1.75},
			{description = "2.00", data = 2},
			{description = "2.50", data = 2.5},
			{description = "3.00", data = 3},
		},
		default = 1,
	},
	{
		name = "RAILCART_PLAYSOUND",
		label = "Play sound",
		hover = "Rail Cart play sound while moving.\nDefault: Yes",
		options =	
		{
			{description = "No", data = false},
			{description = "Yes", data = true},
		},
		default = true,
	},
	{
		name = "RAILCART_SPAWNSMOKE",
		label = "Spawn smoke",
		hover = "Rail Cart spawn smoke while moving (may use up more CPU).\nDefault: Yes",
		options =	
		{
			{description = "No", data = false},
			{description = "Yes", data = true},
		},
		default = true,
	},
	{
		name = "RAILCART_FIREPROOF",
		label = "Fireproof Railway tracks",
		hover = "Make the railway tracks fireproof.\nDefault: No",
		options =	
		{
			{description = "No", data = false},
			{description = "Yes", data = true},
		},
		default = false,
	},
	
}

