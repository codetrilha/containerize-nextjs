FROM node:20-alpine AS base

FROM base AS deps

# Adiciona lib para compatibilidade devido ao 'musl'
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .
RUN npm run build

# Imagem de produção com todas as configurações necessárias
FROM base AS production
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_SHARP_PATH "/app/node_modules/sharp"

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=deps /app/public ./public

# Permissões para poder usar corretamente o prerender do Next.js
RUN mkdir .next
RUN chown nextjs:nodejs .next

COPY --from=deps /app/next.config.mjs ./
COPY --from=deps --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=deps --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

# Standalone output para não precisar usar todas as libs dentro do node_modules
CMD ["node", "server.js"]