import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../color/app_color.dart';

//  AppLoadingIndicator
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: Colors.red));
  }
}

//  ShimmerBox — ek chhota shimmering rectangle/circle, skeleton banane ke
//  liye building block. Left se right animated gradient chalta rehta hai
//  jab tak data load ho raha hota hai.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 12,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
      ),
    );
  }
}

//  AppShimmer — poore subtree par ek baar shimmer animation wrap karta hai
//  taaki sab ShimmerBox ek saath, ek hi gradient ke saath chamke (behtar
//  performance, ek hi AnimationController).
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFF2F2F2),
    this.highlightColor = const Color(0xFFFDECEC),
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = _controller.value * 2 - 1; // -1 -> 1
            return LinearGradient(
              begin: Alignment(dx - 1, 0),
              end: Alignment(dx + 1, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

//  AppListSkeleton — "all tyre / all vehicle" jaise list screens ke liye
//  behtar loader. Real card ke shape jaisa hi ek shimmering placeholder
//  dikhata hai jab tak data aa nahi jaata, taaki loading blank/jarring na
//  lage aur user ko lage ki content load ho raha hai.
class AppListSkeleton extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry margin;

  const AppListSkeleton({
    super.key,
    this.itemCount = 6,
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, __) => Card(
          margin: margin,
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFEFEFEF)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 140, height: 14),
                      SizedBox(height: 10),
                      ShimmerBox(width: 200, height: 10),
                      SizedBox(height: 8),
                      ShimmerBox(width: 160, height: 10),
                      SizedBox(height: 8),
                      ShimmerBox(width: 120, height: 10),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerBox(
                      width: 28,
                      height: 28,
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    SizedBox(height: 8),
                    ShimmerBox(width: 36, height: 10),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//  AppEmptyState
class AppEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color iconColor;

  const AppEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.iconColor = Colors.red,
  });

  const AppEmptyState.offline({super.key, required this.message})
      : icon = Icons.wifi_off,
        iconColor = Colors.grey;

  const AppEmptyState.noResults({super.key, required this.message})
      : icon = Icons.search_off,
        iconColor = Colors.red;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: iconColor),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

//   AppSearchBar  — Standardized search TextField
class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry padding;

  const AppSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText = 'Search...',
    this.suffixIcon,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

//  4. AppTextField

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? labelText;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool enabled;
  final String? errorText;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;

  const AppTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.labelText,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.enabled = true,
    this.errorText,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      focusNode: focusNode,
      enabled: enabled,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        errorText: errorText?.isNotEmpty == true ? errorText : null,
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        disabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: !enabled ? Colors.grey.shade100 : null,
      ),
    );
  }
}

// AppPrimaryButton
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry padding;
  final Color color;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.color = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: width ?? double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: isLoading ? color.withAlpha(153) : color,
        ),
        child: isLoading
            ? const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        )
            : Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

//  AppOutlineButton
class AppOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double? width;

  const AppOutlineButton({
    super.key,
    required this.label,
    this.onTap,
    this.color = Colors.red,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: width ?? double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

//   AppSectionCard
class AppSectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const AppSectionCard({
    super.key,
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              const Divider(),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

// AppInfoRow
class AppInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const AppInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
              valueStyle ??
                  const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

//   AppStatusBadge
class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.backgroundColor = Colors.orange,
    this.textColor = Colors.white,
  });

  const AppStatusBadge.pendingSync({super.key, required this.label})
      : backgroundColor = Colors.orange,
        textColor = Colors.white;

  const AppStatusBadge.active({super.key, required this.label})
      : backgroundColor = Colors.green,
        textColor = Colors.white;

  const AppStatusBadge.inactive({super.key, required this.label})
      : backgroundColor = Colors.grey,
        textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

//  AppListCard
class AppListCard extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color borderColor;

  const AppListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.borderColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: backgroundColor ?? Colors.red.shade50.withAlpha(230),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
        child: ListTile(title: title, subtitle: subtitle, trailing: trailing),
      ),
    );
  }
}

//  AppAppBar
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final Color backgroundColor;
  final Color titleColor;
  final VoidCallback? onBack;

  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.backgroundColor = AppColors.primary,
    this.titleColor = Colors.white,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true,
      title: Text(title, style: TextStyle(color: titleColor)),
      leading: showBack
          ? BackButton(
        color: titleColor,
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      )
          : null,
      actions: actions,
    );
  }
}

//  AppDropdown
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String hintText;
  final String? errorText;
  final bool enabled;

  const AppDropdown({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    required this.hintText,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText?.isNotEmpty == true ? errorText : null,
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        disabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: !enabled ? Colors.grey.shade100 : null,
      ),
    );
  }
}


// AppFilterBadge
class AppFilterBadge extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const AppFilterBadge({
    super.key,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.filter_alt,
              color: isActive ? Colors.red.withAlpha(64) : Colors.red,
            ),
            onPressed: onTap,
          ),
          if (isActive)
            Positioned(
              bottom: 19,
              right: 18,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 9),
              ),
            ),
        ],
      ),
    );
  }
}


//  AppDividerRow
class AppDividerRow extends StatelessWidget {
  final String? label;

  const AppDividerRow({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    if (label == null) return const Divider(height: 1);
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label!,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

//   AppPageBody
class AppPageBody extends StatelessWidget {
  final List<Widget> children;
  final bool safeArea;
  final EdgeInsetsGeometry padding;

  const AppPageBody({
    super.key,
    required this.children,
    this.safeArea = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    Widget body = Padding(
      padding: padding,
      child: Column(children: children),
    );
    return safeArea ? SafeArea(child: body) : body;
  }
}