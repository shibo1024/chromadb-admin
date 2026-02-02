# ========== 阶段 1：依赖安装（充分利用 Docker 层缓存）==========
# 仅 package*.json 变化时此层及后续层才重建；日常改代码不会重新 npm ci
FROM node:20-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci

# ========== 阶段 2：构建 ==========
FROM node:20-alpine AS builder
WORKDIR /app
# 复用 deps 阶段的 node_modules，避免重复安装
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# 构建时禁用 Next 的 telemetry，减少构建噪音
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# ========== 阶段 3：生产运行（最小镜像）==========
# standalone 输出仅包含运行所需：node、server.js、精简 node_modules、静态资源
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
# 使用非 root 用户运行
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# 从 builder 只拷贝 standalone 产物和静态资源
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3001
ENV PORT=3001
ENV HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]
