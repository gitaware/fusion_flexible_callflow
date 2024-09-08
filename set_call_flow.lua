--	set_call_flow.lua
--  based on call_flow.lue by Mark J Crane <markjcrane@fusionpbx.com>
--  Change state of a call flow from commandline
--  BLF's are also updated with this script
--
--  Usage: set_call_flow.lua <call_flow_uuid> [true|false]

	require "resources.functions.config";

	log = require "resources.functions.log".set_call_flow

	local presence_in = require "resources.functions.presence_in"
	local Database    = require "resources.functions.database"

	local dbh = Database.new('system');

	local call_flow_uuid = argv[1];
	local wanted_state = argv[2];

	if not call_flow_uuid then
		log.warning('Can not get call flow uuid')
		return
	end
	
	--log.notice("call_flow_uuid: " .. call_flow_uuid);

--get the call flow details
	local sql = 'SELECT * FROM "v_call_flows" where "call_flow_uuid" = :call_flow_uuid'
		-- .. "and call_flow_enabled = 'true'"
	local params = {call_flow_uuid = call_flow_uuid};
	--log.notice("SQL: " .. sql);
	dbh:query(sql, params, function(row)
		domain_uuid            = row.domain_uuid;
		call_flow_name         = row.call_flow_name;
		call_flow_extension    = row.call_flow_extension;
		call_flow_feature_code = row.call_flow_feature_code;
		--call_flow_context = row.call_flow_context;
		call_flow_status       = row.call_flow_status;
		pin_number             = row.call_flow_pin_number;
		call_flow_label        = row.call_flow_label;
		call_flow_alternate_label = row.call_flow_alternate_label;
		call_flow_sound        = row.call_flow_sound or '';
		call_flow_alternate_sound = row.call_flow_alternate_sound or '';

		if #call_flow_status == 0 then
			call_flow_status = "true";
		end
		if call_flow_status == "true" then
			app = row.call_flow_app;
			data = row.call_flow_data
		else
			app = row.call_flow_alternate_app;
			data = row.call_flow_alternate_data
		end
	end);
	--log.notice("domain_uuid: " .. domain_uuid);


--get the domainname
	local sql = 'SELECT "domain_name" FROM "v_domains" where "domain_uuid" = :domain_uuid'
	local params = {domain_uuid = domain_uuid};
	--log.notice("SQL: %s", sql);
	dbh:query(sql, params, function(row)
		domain_name = row.domain_name;
	end);
	--log.notice("domain_name: " .. domain_name);



	--feature code - toggle the status
	local toggle = (call_flow_status == "true") and "false" or "true"
	if wanted_state then
		if  wanted_state == "true" then
			toggle = "true"
		elseif wanted_state == "false" then
			toggle = "false"
		end
	end
	
	--log.notice("toggle: " .. toggle);

-- turn the lamp
	presence_in.turn_lamp( toggle == "false",
		call_flow_feature_code.."@"..domain_name,
		call_flow_uuid
	);
	if string.find(call_flow_feature_code, 'flow+', nil, true) ~= 1 then
		presence_in.turn_lamp( toggle == "false",
			'flow+'..call_flow_feature_code.."@"..domain_name,
			call_flow_uuid
		);
	end

--active label
	--local active_flow_label = (toggle == "true") and call_flow_label or call_flow_alternate_label

--play info message
	--local audio_file = (toggle == "true") and call_flow_sound or call_flow_alternate_sound

--show in the console
	log.noticef("status=%s,uuid=%s", toggle, call_flow_uuid)

--store in database
	dbh:query('UPDATE "v_call_flows" SET "call_flow_status" = :toggle WHERE "call_flow_uuid" = :call_flow_uuid', {
		toggle = toggle, call_flow_uuid = call_flow_uuid
	});

	return
