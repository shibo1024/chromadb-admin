/** @type {import('next').NextConfig} */
const nextConfig = {
  // 生产镜像：生成独立可运行输出，仅包含运行所需文件，大幅减小镜像体积
  output: 'standalone',
  webpack: (config, { buildId, dev, isServer, defaultLoaders, webpack }) => {
    config.module.rules.push({
      test: /\.node$/,
      use: 'node-loader',
    });

    return config;
  },
}

module.exports = nextConfig
