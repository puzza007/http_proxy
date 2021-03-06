%%% http_trace_SUITE.erl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @author Vance Shipley <vances@globalwavenet.com>
%%% @copyright 2013-2015 Global Wavenet (Pty) Ltd
%%% @end
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%% 
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%% 
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(http_trace_SUITE).

-compile(export_all).

-include_lib("common_test/include/ct.hrl").

suite() ->
	[{userdata, [{info, "This suite tests the HTTP TRACE method"}]},
			% {require, {http_proxy, [port]}},
			{timetrap, {seconds, 60}}].

init_per_suite(Config) ->
	ok = inets:start(),
	Config1 = http_test_lib:start_origin(Config, [{modules, [mod_trace]}]),
	ok = application:start(http_proxy),
	http_test_lib:start_proxy(Config1).

end_per_suite(Config) ->
	Config1 = http_test_lib:stop_proxy(Config),
	ok = application:stop(http_proxy),
	Config2 = http_test_lib:stop_origin(Config1),
	ok = inets:stop(),
	Config2.

all() ->
	[proxy, origin].

proxy() ->
	[{userdata, [{doc, "Test the TRACE method on the proxy server"}]}].

proxy(Config) ->
	Socket = http_test_lib:connect(Config),
	OriginHost = http_test_lib:origin_host(),
	ok = gen_tcp:send(Socket, ["TRACE / HTTP/1.1", [13, 10],
			"Host: ", OriginHost, [13, 10],
			"Max-Forwards: 0", [13, 10, 13, 10]]),
	{ok, {http_response, _, 200, _}} = gen_tcp:recv(Socket, 0),
	ResponseHeaders = http_test_lib:receive_headers(Socket),
	{_, "message/http"} = lists:keyfind('Content-Type', 1, ResponseHeaders),
	{_, ContentLength} = lists:keyfind('Content-Length', 1, ResponseHeaders),
	ok = inet:setopts(Socket,
			[{packet, raw}, {packet_size, list_to_integer(ContentLength)}]),
	gen_tcp:recv(Socket, 0).

origin() ->
	[{userdata, [{doc, "Test the TRACE method on the origin server"}]}].

origin(Config) ->
	Socket = http_test_lib:connect(Config),
	OriginHost = http_test_lib:origin_host(),
	ok = gen_tcp:send(Socket, ["TRACE / HTTP/1.1", [13, 10],
			"Host: ", OriginHost, [13, 10],
			"Max-Forwards: 1", [13, 10, 13, 10]]),
	{ok, {http_response, _, 200, _}} = gen_tcp:recv(Socket, 0),
	ResponseHeaders = http_test_lib:receive_headers(Socket),
	{_, "message/http"} = lists:keyfind('Content-Type', 1, ResponseHeaders),
	{_, ContentLength} = lists:keyfind('Content-Length', 1, ResponseHeaders),
	ok = inet:setopts(Socket,
			[{packet, raw}, {packet_size, list_to_integer(ContentLength)}]),
	gen_tcp:recv(Socket, 0).

