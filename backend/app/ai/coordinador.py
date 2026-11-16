
# COORDINADOR DE INTELIGENCIAS ARTIFICIALES
# ONLY EYES 360

def seleccionar_ia(trabajo):

    # Ollama se encarga de los análisis pesados
    if trabajo == "inventario":
        return "ollama"

    elif trabajo == "ventas":
        return "ollama"

    elif trabajo == "reportes":
        return "ollama"

    # Codex se encarga de la programación
    elif trabajo == "programacion":
        return "codex"

    # Claude revisa el código
    elif trabajo == "revision_codigo":
        return "claude"

    # Gemini apoya con análisis generales
    elif trabajo == "analisis":
        return "gemini"

    # Groq responde consultas rápidas
    elif trabajo == "consulta_rapida":
        return "groq"

    # OpenRouter queda como alternativa
    elif trabajo == "alternativa":
        return "openrouter"

    else:
        return "ollama"
