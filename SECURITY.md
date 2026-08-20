# Segurança & LGPD — Back-end (API)

Postura de segurança da API Rails do sistema de gestão do Centro de Serviços em Psicologia da FACCAT (CESEP). A API concentra as regras de negócio e o tratamento dos **dados sensíveis de saúde** (prontuários e anamnese).

> O front-end que consome esta API tem o seu próprio [SECURITY.md](https://github.com/DKrupp03/faccat-tcc-cesep-front).

## Autenticação
- **Devise + devise-jwt** — autenticação por token JWT.
- **JWT em cookie `HttpOnly`** (não em `localStorage` nem no header `Authorization`): o token fica **fora do alcance do JavaScript**, mitigando roubo de sessão via XSS. Cookie com `Secure` (produção) e `SameSite`. A tradução token↔cookie é feita por um middleware Rack (`lib/middleware/jwt_cookie.rb`), sem alterar o devise-jwt.
- **Proteção CSRF (double-submit token):** como o cookie é enviado automaticamente pelo browser, requisições mutantes autenticadas exigem o header `X-XSRF-TOKEN` casando com o cookie `XSRF-TOKEN`. A validação é feita no próprio middleware (`lib/middleware/jwt_cookie.rb`), no nível do Rack — antes de qualquer filtro de controller (inclusive os *prepends* do Devise).
- **Expiração** de token de 1 dia.
- **Revogação imediata** no logout (estratégia baseada em identificador único por usuário), invalidando o token na hora e expirando o cookie.
- **Senhas** com hash bcrypt e política de complexidade mínima (8+ caracteres com maiúscula, minúscula e número).
- **Confirmação de conta** e **recuperação de senha** por e-mail.

## Autorização
- **Controle de acesso por papel** (admin, terapeuta, paciente):
  - **admin:** acesso total;
  - **terapeuta:** apenas seus pacientes, atendimentos, pagamentos e prontuários;
  - **paciente:** apenas os próprios dados.
- O contexto do usuário autenticado é isolado por requisição, sem vazamento entre requisições concorrentes.

## Transporte e cabeçalhos
- **HTTPS obrigatório** em produção (com HSTS e cookies seguros).
- **Host authorization** (proteção contra DNS rebinding / Host header attacks).

## Rate limiting
- **rack-attack** — throttle **por IP** em login (10/min), recuperação de senha (5/min) e cadastro (5/min), com resposta `429` no contrato JSON da API. Backend do contador: `solid_cache` (banco) em produção.
- **Limitação conhecida (risco aceito para o escopo do TCC):** os throttles são **por IP**, sem limite por conta/e-mail e sem `Devise :lockable` (bloqueio de conta). Um atacante com IPs rotativos não é especificamente contido contra força bruta em uma única conta. Mitigado parcialmente pela política de senha forte. Evolução futura: throttle por conta + `:lockable`.

## CORS
- **rack-cors** — allowlist de origens configurável (apenas o front-end autorizado acessa a API).

## Logs
- Filtragem de parâmetros sensíveis (senhas, tokens) — não são gravados em log.
- Nível de log em produção sem dados de depuração que possam conter dados pessoais.

## Segredos
- Credenciais criptografadas; a chave mestra é injetada apenas em produção (via Kamal) e **nunca** é versionada.
- Variáveis sensíveis ficam em `.env` (fora do git); apenas `.env.example` é versionado.

## Análise de segurança
- **Brakeman** — análise estática de vulnerabilidades.
- **bundler-audit** — verificação de CVEs nas dependências.
- **RuboCop** — padrões de código.

## LGPD — dados sensíveis de saúde
O sistema processa **dados sensíveis** (prontuários e anamnese de pacientes). Diretrizes:
- **Minimização e controle de acesso** por papel (ver Autorização).
- **Eliminação em cascata:** ao remover um paciente, removem-se também seus dados associados (conta, anamnese, atendimentos e prontuários).
- **Logs sem dados pessoais** (ver Logs).
- **TODO (governança):** definir política de **retenção** de prontuários e **auditoria de acessos** (quem leu/alterou dado de paciente).

## Reporte de vulnerabilidades
Por se tratar de um projeto acadêmico (TCC), não há um canal formal de divulgação. Vulnerabilidades podem ser comunicadas em particular ao autor pelo repositório. Por favor, **não** abra issues públicas com detalhes que exponham dados ou facilitem exploração.
