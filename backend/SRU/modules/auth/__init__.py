from SRU.core.registry import register, ModuleInfo

register(ModuleInfo(
    app='SRU.modules.auth',
    slug='auth',
    label='Uwierzytelnianie'
))
