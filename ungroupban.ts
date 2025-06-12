import { CommandContext } from '../../structures/addons/CommandAddons';
import { Command } from '../../structures/Command';
import { discordClient, robloxClient } from '../../main';
import { User, PartialUser } from 'bloxy/dist/structures';
import { getLinkedRobloxUser } from '../../handlers/accountLinks';
import { provider } from '../../database/router';
import { logAction } from '../../handlers/handleLogging';
import {
    getInvalidRobloxUserEmbed,
    getUnexpectedErrorEmbed,
    getSuccessfulGroupUnbanEmbed,
    getNoDatabaseEmbed,
    getUserNotBannedEmbed
} from '../../handlers/locale';
import { config } from '../../config';

class GrupBanKaldirKomutu extends Command {
    constructor() {
        super({
            trigger: 'ungroupban',
            description: 'Bir kişinin grup yasağını kaldırır',
            type: 'ChatInput',
            module: 'admin',
            args: [
                {
                    trigger: 'roblox-kullanici',
                    description: 'Grup yasağını kaldırmak istediğiniz kişi kim?',
                    autocomplete: true,
                    required: true,
                    type: 'RobloxUser'
                },
                {
                    trigger: 'sebep',
                    description: 'Eğer kayıtlarda sebep belirtmek isterseniz buraya yazınız.',
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
    };

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

        if (config.database.enabled) {
            const kullaniciVerisi = await provider.findUser(robloxKullanici.id.toString());
            if (!kullaniciVerisi.isBanned) return ctx.reply({ embeds: [getUserNotBannedEmbed()] });
        }

        try {
            await provider.updateUser(robloxKullanici.id.toString(), {
                isBanned: false
            });
            logAction('Grup Ban Kaldır', ctx.user, ctx.args['sebep'], robloxKullanici);
            return ctx.reply({ embeds: [getSuccessfulGroupUnbanEmbed(robloxKullanici)] });
        } catch (e) {
            console.log(e);
            return ctx.reply({ embeds: [getUnexpectedErrorEmbed()] });
        }
    }
}

export default GrupBanKaldirKomutu;
