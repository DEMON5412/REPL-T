import { CommandContext } from '../../structures/addons/CommandAddons';
import { Command } from '../../structures/Command';
import { discordClient, robloxClient, robloxGroup } from '../../main';
import { User, PartialUser, GroupMember } from 'bloxy/dist/structures';
import { getLinkedRobloxUser } from '../../handlers/accountLinks';
import { checkActionEligibility } from '../../handlers/verificationChecks';
import { provider } from '../../database/router';
import { logAction } from '../../handlers/handleLogging';
import {
    getInvalidRobloxUserEmbed,
    getRobloxUserIsNotMemberEmbed,
    getVerificationChecksFailedEmbed,
    getUnexpectedErrorEmbed,
    getSuccessfulGroupBanEmbed,
    getNoDatabaseEmbed,
    getUserBannedEmbed
} from '../../handlers/locale';
import { config } from '../../config';

class GrupYasaklamaKomutu extends Command {
    constructor() {
        super({
            trigger: 'groupban',
            description: 'Bir kullanıcıyı gruptan yasaklar.',
            type: 'ChatInput',
            module: 'admin',
            args: [
                {
                    trigger: 'roblox-kullanici',
                    description: 'Grup içinden kimi yasaklamak istiyorsunuz?',
                    autocomplete: true,
                    required: true,
                    type: 'RobloxUser'
                },
                {
                    trigger: 'sebep',
                    description: 'Kayıtlarda sebep göstermek isterseniz buraya yazın.',
                    required: false,
                    type: 'String'
                }
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
        if (!config.database.enabled) return ctx.reply({ embeds: [getNoDatabaseEmbed()] });

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
        } catch (err) { };

        if (config.verificationChecks && robloxUye) {
            const eylemUygunlugu = await checkActionEligibility(ctx.user.id, ctx.guild.id, robloxUye, robloxUye.role.rank);
            if (!eylemUygunlugu) return ctx.reply({ embeds: [getVerificationChecksFailedEmbed()] });
        }

        if (config.database.enabled) {
            const kullaniciVerisi = await provider.findUser(robloxKullanici.id.toString());
            if (kullaniciVerisi.isBanned) return ctx.reply({ embeds: [getUserBannedEmbed()] });
        }

        try {
            await provider.updateUser(robloxKullanici.id.toString(), {
                isBanned: true
            });
            if (robloxUye) await robloxGroup.kickMember(robloxKullanici.id);
            logAction('Group Ban', ctx.user, ctx.args['sebep'], robloxKullanici);
            return ctx.reply({ embeds: [getSuccessfulGroupBanEmbed(robloxKullanici)] });
        } catch (e) {
            console.log(e);
            return ctx.reply({ embeds: [getUnexpectedErrorEmbed()] });
        }

    }
}

export default GrupYasaklamaKomutu;
