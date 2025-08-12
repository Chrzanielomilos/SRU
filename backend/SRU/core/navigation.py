from SRU.core.registry import all_modules

def get_menu_items_for(user):
    items = []
    for m in all_modules():
        if m.login_required and not user.is_authenticated:
            continue
        if m.permission and not user.has_perm(m.permission):
            continue
        items.append({
            'label': m.label,
            'slug': m.slug,
            'icon': m.icon,
            'url': f"/api/{m.slug}/",
        })
    return items
