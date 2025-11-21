# TNP Weapon Inspector Pro — Hub README

Resumo
- Interface gráfica para inspecionar e (opcionalmente) modificar configurações de armas do ACS_Engine.ToolStorage em jogos Roblox.
- Interface criada com [`OrionLib`](tnp.lua) e implementada em [tnp.lua](tnp.lua).

Requisitos
- Executor que suporte loadstring/HttpGet e APIs usadas no script.
- Objeto esperado: `ReplicatedStorage.ACS_Engine.ToolStorage` (ver checagem em [`readACSSettings`](tnp.lua)).

Instalação
1. Coloque o arquivo [tnp.lua](tnp.lua) no executor e execute.
2. Garanta que o jogo contenha `ReplicatedStorage.ACS_Engine.ToolStorage`.

Uso rápido
- Aba de inspeção: selecione arma em [`TabWeapons`](tnp.lua) e clique em "Carregar Dados Completos".
- Comparação: use [`TabStats`](tnp.lua) → "Comparar Todas as Armas" para gerar uma tabela.
- Experimental: modificações podem ser aplicadas via [`TabExperimental`](tnp.lua) (atenção a riscos).
- ESP: configuração em [`TabESP`](tnp.lua); ative com o botão que chama [`startESP`](tnp.lua) / [`stopESP`](tnp.lua).

Principais funcionalidades (símbolos)
- Leitura segura de módulos: [`safeRequire`](tnp.lua)
- Leitura de configurações da arma: [`readACSSettings`](tnp.lua)
- Geração de caminhos/estrutura: [`getWeaponPaths`](tnp.lua)
- Serialização para exportar configs: [`serializeTable`](tnp.lua)
- Cálculos úteis: [`calculateDPS`](tnp.lua), [`calculateTTK`](tnp.lua)
- Configuração e runtime ESP: [`espSettings`](tnp.lua), [`startESP`](tnp.lua), [`stopESP`](tnp.lua)

Segurança e aviso
- A aba "Experimental" modifica dados em memória; pode causar kick/ban ou detecção de anti-cheat.
- Use apenas em ambientes de teste e por sua conta e risco.
- Resetar valores reais requer recarregar arma no jogo (cache em [`cachedSettings`](tnp.lua)).

Arquivos no repositório
- [tnp.lua](tnp.lua) — script principal (UI + lógica)
- [a.txt](a.txt) — arquivo adicional (conteúdo não crítico)

Contribuição
- Abra issues ou envie sugestões de melhoria. Mantém o foco em segurança e compatibilidade com proteções ACS.

Licença
- Use conforme regras do jogo/executor; este repositório não se responsabiliza por uso indevido.
