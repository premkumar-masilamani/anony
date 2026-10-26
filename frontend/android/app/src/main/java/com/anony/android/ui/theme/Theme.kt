package com.anony.android.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    primary = CalmingCyan,
    secondary = SageGreen,
    tertiary = MutedLavender,
    background = MidnightSlate,
    surface = ElevatedCard,
    onPrimary = MidnightSlate,
    onSecondary = MidnightSlate,
    onBackground = TextPrimary,
    onSurface = TextPrimary
)

@Composable
fun AnonyTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = Typography,
        content = content
    )
}
