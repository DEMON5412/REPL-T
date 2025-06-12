import { CommandContext } from '../../structures/addons/CommandAddons';
import { Command } from '../../structures/Command';
import {
    getSuccessfulRevertRanksEmbed,
    getInvalidDurationEmbed,
    getInvalidRobloxUserEmbed,
} from '../../handlers/locale';
import { config } from '../../config';
import { discordClient, robloxClient, robloxGroup } from '../../main';
import ms from 'ms';
import { logAction } from '../../handlers/handleLogging';
import { PartialUser, User } from 'bloxy/dist/structures';
import { getLinkedRobloxUser } from '../../handlers/accountLinks';

class RütbeGeriAlKomutu extends Command {
    constructor() {
        super({
            trigger: 'revertranks',
            description: 'Belirtilen süre içerisindeki tüm rütbe değişikliklerini geri alır.',
            type: 'ChatInput',
            module: 'admin',
            args: [
                {
                    trigger: 'süre',
                    description: 'Kaç dakikalık rütbe değişikliklerini geri almak istiyorsunuz?',
                    type: 'String',
                },
                {
                    trigger: 'filtre',
                    description: 'İşlemleri belli bir Roblox kullanıcısına mı filtrelemek istiyorsunuz?',
                    autocomplete: true,
                    required: false,
                    type: 'RobloxUser',
                },
                {
                    trigger: 'sebep',
                    description: 'Kayıtlarda sebep göstermek isterseniz buraya yazın.',
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
        if (ctx.args['filtre']) {
            try {
                robloxKullanici = await robloxClient.getUser(ctx.args['filtre'] as number);
            } catch (err) {
                try {
                    const robloxKullanicilar = await robloxClient.getUsersByUsernames([ctx.args['filtre'] as string]);
                    if (robloxKullanicilar.length === 0) throw new Error();
                    robloxKullanici = robloxKullanicilar[0];
                } catch (err) {
                    try {
                        const idSorgu = ctx.args['filtre'].replace(/[^0-9]/gm, '');
                        const discordKullanici = await discordClient.users.fetch(idSorgu);
                        const bagliKullanici = await getLinkedRobloxUser(discordKullanici.id, ctx.guild.id);
                        if (!bagliKullanici) throw new Error();
                        robloxKullanici = bagliKullanici;
                    } catch (err) {
                        return ctx.reply({ embeds: [getInvalidRobloxUserEmbed()] });
                    }
                }
            }
        }

        const denetimKayitlari = await robloxClient.apis.groupsAPI.getAuditLogs({
            groupId: robloxGroup.id,
            actionType: 'ChangeRank',
            limit: 100,
        });

        let sure: number;
        try {
            sure = Number(ms(ctx.args['süre']));
            if (!sure) throw new Error();
            if (sure < 0.5 * 60000 || sure > 8.64e+7) return ctx.reply({ embeds: [getInvalidDurationEmbed()] });
        } catch (err) {
            return ctx.reply({ embeds: [getInvalidDurationEmbed()] });
        }

        const maksimumTarih = new Date();
        maksimumTarih.setMilliseconds(maksimumTarih.getMilliseconds() - sure);

        const etkilenenKayitlar = denetimKayitlari.data.filter((log) => {
            if (log.actor.user.userId === robloxClient.user.id && !(robloxKullanici && robloxKullanici.id === robloxClient.user.id)) return;
            if (robloxKullanici && robloxKullanici.id !== log.actor.user.userId) return;
            const logOlusturmaTarihi = new Date(log.created);
            return logOlusturmaTarihi > maksimumTarih;
        });

        etkilenenKayitlar.forEach(async (log, index) => {
            setTimeout(async () => {
                await robloxGroup.updateMember(log.description['TargetId'], log.description['OldRoleSetId']);
            }, index * 1000);
        });

        logAction('Rütbe Geri Al', ctx.user, ctx.args['sebep'], null, null, maksimumTarih);
        return ctx.reply({ embeds: [getSuccessfulRevertRanksEmbed(etkilenenKayitlar.length)] });
    }
}

export default RütbeGeriAlKomutu;
