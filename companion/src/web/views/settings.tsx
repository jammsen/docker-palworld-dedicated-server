import type { EffectiveSetting } from "../../settings/store.js";
import { settingGroups } from "../../settings/schema.js";
import { Layout } from "./layout.js";

export interface SettingsPageProps {
  t: (key: string) => string;
  language: string;
  csrf: string;
  settings: EffectiveSetting[];
  readOnly: boolean;
  restartPending: boolean;
  saved?: number;
  errors?: string[];
}

function SettingInput({ setting, readOnly }: { setting: EffectiveSetting; readOnly: boolean }) {
  const { spec, value } = setting;
  const disabled = readOnly || spec.excluded === true;
  if (spec.secret) {
    return <input type="password" value="" placeholder="••••••••" disabled />;
  }
  if (spec.type === "bool") {
    return (
      <select name={spec.key} disabled={disabled}>
        <option value="true" selected={value === "true"}>
          true
        </option>
        <option value="false" selected={value === "false"}>
          false
        </option>
      </select>
    );
  }
  if (spec.type === "enum") {
    return (
      <select name={spec.key} disabled={disabled}>
        {(spec.values ?? []).map((option) => (
          <option value={option} selected={value === option}>
            {option}
          </option>
        ))}
      </select>
    );
  }
  if (spec.type === "int" || spec.type === "float") {
    return (
      <input
        type="number"
        name={spec.key}
        value={value}
        min={spec.min}
        max={spec.max}
        step={spec.type === "int" ? 1 : (spec.step ?? "any")}
        disabled={disabled}
      />
    );
  }
  return <input type="text" name={spec.key} value={value} disabled={disabled} />;
}

function ProvenanceBadge({ setting, t }: { setting: EffectiveSetting; t: (key: string) => string }) {
  if (setting.spec.excluded) {
    return <span class="badge excluded">{t("settings.provenance.excluded")}</span>;
  }
  return <span class={`badge ${setting.provenance}`}>{t(`settings.provenance.${setting.provenance}`)}</span>;
}

export function SettingsPage({ t, language, csrf, settings, readOnly, restartPending, saved, errors }: SettingsPageProps) {
  return (
    <Layout t={t} language={language} activeNav="settings" csrf={csrf}>
      <h1>⚙️ {t("settings.title")}</h1>

      {readOnly ? <p class="status-banner warn">⚠️ {t("settings.manualMode")}</p> : null}
      {restartPending ? (
        <div class="status-banner warn restart-banner">
          <span>🔄 {t("settings.restartPending")}</span>
          <form method="post" action="/actions/restart" class="inline">
            <input type="hidden" name="_csrf" value={csrf} />
            <button type="submit">{t("settings.restartNow")}</button>
          </form>
        </div>
      ) : null}
      {saved !== undefined && saved > 0 ? <p class="status-banner online">✅ {t("settings.saved")}</p> : null}
      {errors && errors.length > 0 ? (
        <div class="status-banner error-banner">
          <strong>{t("settings.validationFailed")}</strong>
          <ul>
            {errors.map((error) => (
              <li>{error}</li>
            ))}
          </ul>
        </div>
      ) : null}

      <p class="hint">{t("settings.precedenceNote")}</p>
      <p>
        <a href="/settings/export" download="palworld-settings.env">
          ⬇️ {t("settings.export")}
        </a>
      </p>

      <form method="post" action="/settings/save">
        <input type="hidden" name="_csrf" value={csrf} />
        {settingGroups.map((group) => {
          const groupSettings = settings.filter((s) => s.spec.group === group);
          if (groupSettings.length === 0) return null;
          return (
            <section>
              <h2>{t(`settings.group.${group}`)}</h2>
              <table class="settings-table">
                <tbody>
                  {groupSettings.map((setting) => (
                    <tr>
                      <td class="setting-key">
                        <code>{setting.spec.key}</code>
                      </td>
                      <td>
                        <SettingInput setting={setting} readOnly={readOnly} />
                      </td>
                      <td>
                        <ProvenanceBadge setting={setting} t={t} />
                      </td>
                      <td>
                        {setting.provenance === "override" && !readOnly ? (
                          <button
                            type="submit"
                            name="_reset"
                            value={setting.spec.key}
                            formaction="/settings/reset"
                            class="linklike"
                            title={`${t("settings.resetTo")} ${setting.envValue}`}
                          >
                            {t("settings.reset")}
                          </button>
                        ) : null}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </section>
          );
        })}
        {!readOnly ? (
          <div class="save-row">
            <button type="submit">{t("settings.save")}</button>
            <button type="submit" formaction="/settings/reset" name="_reset" value="__all__" class="linklike">
              {t("settings.resetAll")}
            </button>
          </div>
        ) : null}
      </form>
    </Layout>
  );
}
