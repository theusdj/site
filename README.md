# Abel Arena — Interclasse Abel Pereira de Castro

Site estático (HTML + JS, sem build) ligado ao **Supabase**: banco PostgreSQL, login real, RLS e atualização em tempo real.

## Arquivos
- `index.html` — site público + painel `#admin`
- `config.js` — URL e chave **anon** do seu projeto
- `schema.sql` — tabelas, índices, RLS, auditoria, realtime, modalidades (Futsal, Vôlei, Queimada)

## Passo a passo
1. Crie um projeto grátis em supabase.com.
2. **SQL Editor** → cole e rode todo o `schema.sql`.
3. **Authentication → Providers → Email**: desative *Allow new users to sign up* (só a organização entra). Em **Users → Add user**, crie seu e-mail e senha.
4. Rode no SQL Editor (troque o e-mail):
   `insert into profiles(id,name,role) select id,'Seu nome','admin' from auth.users where email='seu@email.com';`
5. **Project Settings → API**: copie *Project URL* e a chave **anon public** para o `config.js`.
6. Publique a pasta inteira (Netlify Drop, Cloudflare Pages ou GitHub Pages). Abra o site, clique em **Admin** e entre.
7. Cadastre equipes, crie partidas, clique em **Iniciar**, lance gols e **Encerrar**. Todos os visitantes veem a mudança sem recarregar.

## Segurança
- A chave `anon` pode ficar no navegador; o que protege os dados são as políticas RLS. Visitantes só leem; escrever exige login + papel (`admin`/`organizer` para jogos e equipes, `admin`/`editor` para notícias).
- **Nunca** use a chave `service_role` no site.
- Toda alteração de partida é registrada na tabela `audit_log` por trigger no servidor.

## Papéis
Para criar outro organizador/editor: crie o usuário em Authentication e insira em `profiles` com `role` = `organizer` ou `editor`.

## Ainda não incluso (próximas etapas)
Editar/excluir equipes e partidas pela interface (por ora, use *Table Editor* do Supabase), upload de imagens (Storage), chaves eliminatórias, grupos/fases configuráveis, regras de desempate configuráveis (hoje: 3 pts vitória, 1 empate, saldo, gols pró), página de detalhes da partida, galeria e edição dos textos institucionais.
