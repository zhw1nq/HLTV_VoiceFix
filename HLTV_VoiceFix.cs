using CounterStrikeSharp.API;
using CounterStrikeSharp.API.Core;

namespace HLTV_VoiceFix;
public class HLTV_VoiceFix : BasePlugin
{
    public override string ModuleName => "Fix Voice Chat in Demo Recordings";
    public override string ModuleAuthor => "zhw1nq";
    public override string ModuleVersion => "3.1.0";

    public override void Load(bool hotReload)
    {
        RegisterEventHandler<EventRoundStart>(((roundStartEvent, eventInfo) =>
        {
            Server.NextFrame(() =>
            {
                HLTV_VoiceChat();
            });
            return HookResult.Continue;
        }));
    }

    void HLTV_VoiceChat()
    {
        var hltvPlayer = Utilities.GetPlayers().Where(player => player.IsHLTV).FirstOrDefault();

        if (hltvPlayer != null && hltvPlayer.IsValid)
        {
            hltvPlayer.VoiceFlags = VoiceFlags.All | VoiceFlags.ListenAll;
        }
    }
}