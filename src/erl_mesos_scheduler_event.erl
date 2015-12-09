-module(erl_mesos_scheduler_event).

-include("erl_mesos.hrl").

-include("erl_mesos_obj.hrl").

-export([parse_obj/1]).

-type event() :: {subscribed, {subscribed_event(), pos_integer}} |
                 {offers, [offer()]} |
                 {error, error_event()} |
                 heartbeat |
                 erl_mesos_obj:data_obj().
-export_type([event/0]).

-define(DEFAULT_HEARTBEAT_INTERVAL_SECONDS, 15). %% Seconds.

%% External functions.

%% @doc Parses obj.
-spec parse_obj(erl_mesos_obj:data_obj()) -> event().
parse_obj(Obj) ->
    case erl_mesos_obj:get_value(<<"type">>, Obj) of
        <<"SUBSCRIBED">> ->
            {subscribed, parse_subscribed_obj(Obj)};
        <<"OFFERS">> ->
            {offers, parse_offer_objs(Obj)};
        <<"ERROR">> ->
            {error, parse_error_obj(Obj)};
        <<"HEARTBEAT">> ->
            heartbeat;
        _Type ->
            Obj
    end.

%% Internal functions.

%% @doc Parses subscribed obj.
%% @private
-spec parse_subscribed_obj(erl_mesos_obj:data_obj()) ->
    {subscribed_event(), pos_integer()}.
parse_subscribed_obj(Obj) ->
    SubscribedObj = erl_mesos_obj:get_value(<<"subscribed">>, Obj),
    #subscribed_event{framework_id = FrameworkIdObj,
                      heartbeat_interval_seconds = HeartbeatIntervalSeconds} =
        ?ERL_MESOS_OBJ_TO_RECORD(subscribed_event, SubscribedObj),
    FrameworkId = ?ERL_MESOS_OBJ_TO_RECORD(framework_id, FrameworkIdObj),
    HeartbeatIntervalSeconds1 =
        heartbeat_interval_seconds(HeartbeatIntervalSeconds),
    {#subscribed_event{framework_id = FrameworkId,
                       heartbeat_interval_seconds = HeartbeatIntervalSeconds1},
                      HeartbeatIntervalSeconds1 * 1000}.

%% @doc Returns heartbeat interval.
%% @private
-spec heartbeat_interval_seconds(undefined | pos_integer()) -> pos_integer().
heartbeat_interval_seconds(undefined) ->
    ?DEFAULT_HEARTBEAT_INTERVAL_SECONDS;
heartbeat_interval_seconds(HeartbeatIntervalSeconds) ->
    HeartbeatIntervalSeconds.

%% @doc Parses error obj.
%% @private
-spec parse_error_obj(erl_mesos_obj:data_obj()) -> error_event().
parse_error_obj(Obj) ->
    ?ERL_MESOS_OBJ_TO_RECORD(error_event, Obj).

%% @doc Parses offer objs.
%% @private
-spec parse_offer_objs(erl_mesos_obj:data_obj()) -> [offer()].
parse_offer_objs(Obj) ->
    _OfferObjs = erl_mesos_obj:get_value(<<"offers">>, Obj),
    [#offer{}].
