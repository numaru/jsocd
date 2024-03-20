import { resolve } from 'path'
import { defineConfig } from 'vite'

// https://vitejs.dev/config/
export default defineConfig({
    build: {
        lib: {
            entry: resolve(__dirname, 'src/index.js'),
            name: 'jsocd',
        },
        outDir: resolve(__dirname, 'build/package'),
        emptyOutDir: false
    }
})
