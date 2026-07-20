package com.simphiwe.letsapply;

import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.Locale;

final class SalaryFormatter {
    private SalaryFormatter() {}

    static String format(String currency, int min, int max, String period) {
        if (min <= 0 && max <= 0) {
            return "Salary not disclosed";
        }

        String symbol = symbolFor(currency);
        String suffix = suffixFor(period);

        if (min > 0 && max > 0 && min != max) {
            return symbol + formatNumber(min) + " to " + symbol + formatNumber(max) + " " + suffix;
        }

        int amount = min > 0 ? min : max;
        return symbol + formatNumber(amount) + " " + suffix;
    }

    private static String symbolFor(String currency) {
        if (currency == null) {
            return "R";
        }

        switch (currency.toUpperCase(Locale.ROOT)) {
            case "ZAR":
                return "R";
            case "USD":
                return "$";
            case "GBP":
                return "£";
            case "EUR":
                return "€";
            default:
                return currency.toUpperCase(Locale.ROOT) + " ";
        }
    }

    private static String suffixFor(String period) {
        if (period == null || period.trim().isEmpty()) {
            return "per annum";
        }

        String cleaned = period.trim();
        String normalized = cleaned.toLowerCase(Locale.ROOT);
        if (normalized.startsWith("per ")) {
            return cleaned;
        }

        switch (normalized) {
            case "annum":
            case "annual":
            case "year":
            case "yearly":
                return "per annum";
            case "month":
            case "monthly":
                return "per month";
            case "week":
            case "weekly":
                return "per week";
            case "hour":
            case "hourly":
                return "per hour";
            case "day":
            case "daily":
                return "per day";
            default:
                return cleaned;
        }
    }

    private static String formatNumber(int amount) {
        DecimalFormatSymbols symbols = new DecimalFormatSymbols(Locale.US);
        symbols.setGroupingSeparator(' ');
        DecimalFormat formatter = new DecimalFormat("#,###", symbols);
        return formatter.format(amount);
    }
}
