import { discordClient, robloxClient, robloxGroup } from '../../main';
import { CommandContext } from '../../structures/addons/CommandAddons';
import { Command } from '../../structures/Command';
import {
    getInvalidRobloxUserEmbed,
    getRobloxUserIsNotMemberEmbed,
    getSuccessfulExileEmbed,
    getUnexpectedErrorEmbed,
    getNoRankBelowEmbed,
    getRoleNotFoundEmbed,
    getVerificationChecksFailedEmbed,
    getUserSuspendedEmbed,
} from '../../handlers/locale';
import { config } from '../../config';
import { User, PartialUser, GroupMember } from 'bloxy/dist/structures';
import { checkActionEligibility } from '../../handlers/verificationChecks';
import { logAction } from '../../handlers/handleLogging';
import { getLinkedRobloxUser } from '../../handlers/accountLinks';
import { provider } from '../../database/router';

class SürgünKomutu extends Command {
    constructor() {
        super({
            trigger: 'exile',
            description: 'Roblox grubundan bir kullanıcıyı sürgün eder.',
            type: 'ChatInput',
            module: 'admin',
            args: [
                {
                    trigger: 'roblox-kullanici',
                    description: 'Kimi sürgün etmek istiyorsunuz?',
                    autocomplete: true,
                    type: 'RobloxUser',
                },
                {
                    trigger: 'sebep',
                    description: 'Eğer kayıtlar için bir sebep belirtmek istiyorsanız buraya yazın.',
                    isLegacyFlag: true,
                    required: false,
                    type: 'String',
                },
            ],
            permissions: [
                {
                    type: 'role',
                    ids: config.permissions.admin,
                    value: true,
                }
            ]
        });
    }

    async run(ctx: CommandContext) {
        let robloxKullanici: User | PartialUser;

        try {
            robloxKullanici = await robloxClient.getUser(ctx.args['roblox-kullanici'] as number);
        } catch (err) {
            try {
                const robloxKullanicilar = await robloxClient.getUsersByUsernames([ctx.args['roblox-kullanici'] as string]);
                if (robloxKullanicilar.length === 0) throw new Error();
                robloxKullanici = robloxKullanicilar[0];
            } catch (err) {
                try {
                    const idSorgu = ctx.args['roblox-kullanici'].replace(/[^0-9]/gm, '');
                    const discordKullanici = await discordClient.users.fetch(idSorgu);
                    const bagliKullanici = await getLinkedRobloxUser(discordKullanici.id, ctx.guild.id);
                    if (!bagliKullanici) throw new Error();
                    robloxKullanici = bagliKullanici;
                } catch (err) {
                    return ctx.reply({ embeds: [getInvalidRobloxUserEmbed()] });
                }
            }
        }

        let robloxUye: GroupMember;
        try {
            robloxUye = await robloxGroup.getMember(robloxKullanici.id);
            if (!robloxUye) throw new Error();
        } catch (err) {
            return ctx.reply({ embeds: [getRobloxUserIsNotMemberEmbed()] });
        }

        if (config.verificationChecks) {
            const eylemUygunlugu = await checkActionEligibility(ctx.user.id, ctx.guild.id, robloxUye, robloxUye.role.rank);
            if (!eylemUygunlugu) return ctx.reply({ embeds: [getVerificationChecksFailedEmbed()] });
        }

        if (config.database.enabled) {
            const kullaniciVerisi = await provider.findUser(robloxKullanici.id.toString());
            if (kullaniciVerisi.suspendedUntil) return ctx.reply({ embeds: [getUserSuspendedEmbed()] });
        }

        try {
            await robloxUye.kickFromGroup(config.groupId);
            ctx.reply({ embeds: [await getSuccessfulExileEmbed(robloxKullanici)] });
            logAction('Exile', ctx.user, ctx.args['sebep'], robloxKullanici);
        } catch (err) {
            console.log(err);
            return ctx.reply({ embeds: [getUnexpectedErrorEmbed()] });
        }
    }
}

export default SürgünKomutu;
