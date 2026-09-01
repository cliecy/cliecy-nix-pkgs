'use strict'

const { ipcRenderer } = require('electron')

const buttonActions = Object.freeze({
    'header-minimize': 'window-minimize',
    'header-maximize': 'window-maximize',
    'header-close': 'window-close',
    'header-on-top': 'window-toggle-always-on-top',
})

window.addEventListener('DOMContentLoaded', () => {
    document.title = '抖音'

    const disableMiddleClick = (event) => {
        if (event.button !== 1) return

        event.preventDefault()
        event.stopPropagation()
        event.stopImmediatePropagation()
    }

    document.addEventListener('mousedown', disableMiddleClick, {capture: true})
    document.addEventListener('auxclick', disableMiddleClick, {capture: true})

    let windowState = null

    const applyWindowState = () => {
        if (!windowState) return

        const maximizeButton = document.querySelector('[data-e2e="header-maximize"]')
        if (maximizeButton) {
            maximizeButton.dataset.windowState = windowState.maximized ? 'maximized' : 'normal'
        }

        const onTopButton = document.querySelector('[data-e2e="header-on-top"]')
        if (onTopButton) {
            onTopButton.dataset.onTopState = windowState.alwaysOnTop ? 'on' : 'off'
        }
    }

    const setupTitleBarButtons = () => {
        for (const [selector, action] of Object.entries(buttonActions)) {
            const button = document.querySelector(`[data-e2e="${selector}"]`)
            if (!button || button.dataset.dyHooked) continue

            button.dataset.dyHooked = '1'
            button.addEventListener('click', (event) => {
                event.preventDefault()
                event.stopPropagation()
                event.stopImmediatePropagation()
                ipcRenderer.send('window-action', action)
            }, {capture: true})
        }

        applyWindowState()
    }

    ipcRenderer.invoke('get-window-state').then((state) => {
        windowState = state
        applyWindowState()
    }).catch(() => {})

    ipcRenderer.on('window-state-changed', (_event, state) => {
        windowState = state
        applyWindowState()
    })

    const style = document.createElement('style')
    style.textContent = `
        [data-e2e="header-on-top"][data-on-top-state="on"] { opacity: 0.55; }
        [data-e2e="header-on-top"][data-on-top-state="off"] { opacity: 1; }
        [data-e2e="header-on-top"]:hover { opacity: 1 !important; }
    `
    document.head.appendChild(style)

    setupTitleBarButtons()

    let observerTimer = null
    const observer = new MutationObserver(() => {
        if (observerTimer) return

        observerTimer = setTimeout(() => {
            observerTimer = null
            setupTitleBarButtons()
        }, 200)
    })
    observer.observe(document.body, {childList: true, subtree: true})

    document.addEventListener('click', (event) => {
        const target = event.target
        const svg = target?.closest?.('svg')
        if (!svg) return

        const arrowPath = svg.querySelector('path[stroke-linecap="round"]')
        const pathData = arrowPath?.getAttribute('d') || ''
        if (!/^M1[5-9]/.test(pathData) || !/L8\./.test(pathData)) return

        event.preventDefault()
        event.stopPropagation()
        event.stopImmediatePropagation()
        ipcRenderer.send('go-back')
    }, {capture: true})
})
